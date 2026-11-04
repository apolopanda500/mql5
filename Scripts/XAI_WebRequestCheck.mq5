//+------------------------------------------------------------------+
//|                                         XAI_WebRequestCheck.mq5 |
//|  Verifica a lista "Allow WebRequest for listed URL" do terminal. |
//|                                                                  |
//|  Como ler o resultado no journal (Especialistas):                |
//|    PERMITIDA   -> a URL passou na lista (o erro, se houver, e de |
//|                   rede/HTTP e nao de permissao).                 |
//|    BLOQUEADA   -> 4014 = nao permitido (lista OU checkbox); o veredito do fim diz qual     |
//|                   4060 = URL/dominio fora da lista permitida.    |
//|                                                                  |
//|  Nenhum dado de conta, ordem ou credencial e enviado: o pedido e |
//|  um GET sem corpo e sem cabecalhos.                              |
//+------------------------------------------------------------------+
#property copyright "XAU_AI_PRO"
#property version   "1.00"
#property script_show_inputs

// URLs separadas por ';'. Inclui as que o projeto realmente usa e
// candidatas comuns, para o operador conferir o que ja cadastrou.
// 04/11/2026: 9001 e o MCP embutido do MT5, nao o gateway. A lista abaixo
// testa a porta real (9011) em tres formas + o controlo 9001, que ja se
// provou permitido em 03/11 23:36. Se o 9011 der 401/200/404, esta na lista;
// se der 4014/4060, nao esta.
input string UrlList   = "http://127.0.0.1:9011/api/ai/predict;http://127.0.0.1:9011/;http://localhost:9011/api/ai/predict;http://127.0.0.1:9001/api/ai/predict"; // URLs a testar (separadas por ;)
input string Method    = "GET";   // Verbo HTTP (GET ou POST)
input int    TimeoutMs = 5000;    // Timeout por pedido (ms)

//+------------------------------------------------------------------+
string DescribeError(const int err)
{
   switch(err)
   {
      // P2.19: 4014 tem DUAS causas. Dizer so "desabilitado" manda o
      // operador ao lugar errado quando o checkbox esta ligado e o defeito
      // e a lista. O veredito do fim resolve qual das duas e.
      case 4014: return "NAO PERMITIDO (URL fora da lista, ou checkbox desligado)";
      case 4060: return "URL FORA DA LISTA (Allow WebRequest for listed URL)";
      case 5200: return "URL invalida (conferir http:// ou https:// e o dominio)";
      case 5201: return "conexao falhou (lista OK, host inacessivel)";
      case 5202: return "timeout (lista OK, host lento ou fora)";
      case 5203: return "pedido falhou (lista OK, resposta invalida)";
   }
   return "erro " + IntegerToString(err);
}

//+------------------------------------------------------------------+
void OnStart()
{
   string urls[];
   int total = StringSplit(UrlList, ';', urls);
   if(total <= 0)
   {
      Print("[WEBREQ] lista de URLs vazia");
      return;
   }

   Print("[WEBREQ] inicio | pedidos=", total, " | metodo=", Method,
         " | timeout_ms=", TimeoutMs);

   int permitidas = 0;
   int bloqueadas = 0;
   int outras     = 0;
   int naoListadas = 0;        // P2.19: 4014/4060 - candidatas a lista
   string pendentes = "";      // P2.19: URLs que faltam autorizar

   for(int i = 0; i < total; i++)
   {
      string url = urls[i];
      StringTrimLeft(url);
      StringTrimRight(url);
      if(StringLen(url) == 0)
         continue;

      char   post[], result[];
      string result_headers = "";

      ResetLastError();
      int status = WebRequest(Method, url, "", TimeoutMs, post, result, result_headers);
      int err    = GetLastError();

      if(status != -1)
      {
         permitidas++;
         Print("[WEBREQ] PERMITIDA | ", url, " | HTTP=", status,
               " | body_bytes=", ArraySize(result));
         continue;
      }

      // -1: a chamada nao chegou a producao. O codigo diz se foi lista ou rede.
      if(err == 4014 || err == 4060)
      {
         bloqueadas++;
         naoListadas++;
         if(StringLen(pendentes) > 0)
            pendentes += ";";
         pendentes += url;
         Print("[WEBREQ] BLOQUEADA | ", url, " | ", DescribeError(err));
      }
      else if(err == 5200)
      {
         bloqueadas++;
         Print("[WEBREQ] BLOQUEADA | ", url, " | ", DescribeError(err));
      }
      else if(err == 5201 || err == 5202 || err == 5203)
      {
         permitidas++;
         Print("[WEBREQ] PERMITIDA | ", url, " | ", DescribeError(err));
      }
      else
      {
         outras++;
         Print("[WEBREQ] INDEFINIDA | ", url, " | ", DescribeError(err));
      }
   }

   Print("[WEBREQ] fim | permitidas=", permitidas,
         " | bloqueadas=", bloqueadas, " | indefinidas=", outras);

   // P2.19 (03/11/2026): separar as duas causas do 4014 por EVIDENCIA, nao por
   // suposicao. Medido as 23:18:44 neste terminal: 9001/api/ai/predict passou
   // (HTTP=401, logo entrou na lista) e as outras 5 deram 4014. Isso PROVA
   // checkbox ligado e lista incompleta - o oposto do que a mensagem antiga
   // afirmava ("desabilitado nas opcoes"), que mandava o operador conferir um
   // controle que ja estava certo.
   if(permitidas > 0 && naoListadas > 0)
     {
      Print("[WEBREQ] VEREDITO | WebRequest esta LIGADO (", permitidas,
            " URL(s) passaram a lista) | o defeito e a LISTA, nao o checkbox");
      Print("[WEBREQ] ACAO | Ferramentas > Opcoes > Expert Advisors > ",
            "Allow WebRequest for listed URL > Add, uma por vez: ", pendentes);
     }
   else if(permitidas == 0 && naoListadas > 0)
     {
      Print("[WEBREQ] VEREDITO | nenhuma URL passou | o checkbox pode estar ",
            "DESLIGADO, ou a lista VAZIA | confira o checkbox e adicione: ", pendentes);
     }
   else if(permitidas > 0 && naoListadas == 0)
     {
      Print("[WEBREQ] VEREDITO | todas as URLs testadas estao na lista | WebRequest OK");
     }
}
//+------------------------------------------------------------------+
