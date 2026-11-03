//+------------------------------------------------------------------+
//|                                         XAI_WebRequestCheck.mq5 |
//|  Verifica a lista "Allow WebRequest for listed URL" do terminal. |
//|                                                                  |
//|  Como ler o resultado no journal (Especialistas):                |
//|    PERMITIDA   -> a URL passou na lista (o erro, se houver, e de |
//|                   rede/HTTP e nao de permissao).                 |
//|    BLOQUEADA   -> 4014 = WebRequest desabilitado nas opcoes;     |
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
input string UrlList   = "http://127.0.0.1:9001/api/ai/predict;https://api.telegram.org;https://api.openai.com;https://generativelanguage.googleapis.com;https://api.anthropic.com;https://www.mql5.com"; // URLs a testar (separadas por ;)
input string Method    = "GET";   // Verbo HTTP (GET ou POST)
input int    TimeoutMs = 5000;    // Timeout por pedido (ms)

//+------------------------------------------------------------------+
string DescribeError(const int err)
{
   switch(err)
   {
      case 4014: return "WebRequest DESABILITADO em Opcoes > Expert Advisors";
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
}
//+------------------------------------------------------------------+
