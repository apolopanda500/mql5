//+------------------------------------------------------------------+
//| DiagGateSelfTest.mq5                                             |
//| XAU_AI_PRO v1.2.42 - P1.17                                       |
//+------------------------------------------------------------------+
// AUTO-TESTE DO PORTAO DE DIAGNOSTICO
//
// NAO NEGOCEIA. Nao cria, modifica nem fecha ordem ou posicao.
// Nao le conta, nao le risco, nao depende de simbolo. Exercita
// apenas DiagGateAllow()/DiagGateSummary(), que sao funcoes puras
// sobre uma tabela global em memoria.
//
// Motivo: o portao foi compilado no EA mas nunca executou. Se
// suprimir a primeira ocorrencia, ou suprimir mudanca de desfecho,
// todas as medicoes seguintes do journal ficam invalidas. Este
// script prova o comportamento antes de confiar nele.
//
// Esperado: 4 linhas suprimidas no bloco A (A2, A4, A5, A7); o bloco C prova
// que um ciclo de 3 estados escreve 3 linhas e depois cala, mesmo com 3000 voltas.
//+------------------------------------------------------------------+
#property description "Auto-teste de Monitoring/DiagGate.mqh (P1.17). Nao negoceia."
#property version     "1.000"

#include "Monitoring/DiagGate.mqh"

int g_falhas = 0;

//+------------------------------------------------------------------+
void Check(const string nome, const bool obtido, const bool esperado)
{
   bool ok = (obtido == esperado);
   if(!ok)
      g_falhas++;

   Print("[DIAGGATE-TEST] ", (ok ? "OK   " : "FALHA"), " | ", nome,
         " | obtido=", (obtido ? "true" : "false"),
         " | esperado=", (esperado ? "true" : "false"));
}

//+------------------------------------------------------------------+
void OnStart()
{
   Print("[DIAGGATE-TEST] inicio | TimeCurrent=", TimeToString(TimeCurrent(), TIME_DATE | TIME_SECONDS));

   //--------------------------------------------- A1..A7: regra basica
   // A1 - primeiro desfecho de cada simbolo/tag sai sempre.
   Check("A1 primeiro desfecho sai", DiagGateAllow("XAUUSD", "TESTE", "estado-A", 0), true);

   // A2 - mesmo desfecho, sem heartbeat: suprime.
   Check("A2 desfecho igual suprime", DiagGateAllow("XAUUSD", "TESTE", "estado-A", 0), false);

   // A3 - desfecho MUDOU: sai na hora (sinal operacional).
   Check("A3 desfecho novo sai", DiagGateAllow("XAUUSD", "TESTE", "estado-B", 0), true);

   // A4 - heartbeat pedido mas ainda nao venceu: suprime.
   Check("A4 heartbeat nao vencido suprime", DiagGateAllow("XAUUSD", "TESTE", "estado-B", 3600), false);

   // A5 - heartbeat 0 (silencio total) continua a suprimir.
   Check("A5 heartbeat 0 suprime", DiagGateAllow("XAUUSD", "TESTE", "estado-B", 0), false);

   // A6 - a chave e por SIMBOLO: outro simbolo com o mesmo desfecho sai.
   Check("A6 outro simbolo sai", DiagGateAllow("EURUSD", "TESTE", "estado-B", 0), true);

   // A7 - e o segundo do novo simbolo suprime (chave independente).
   Check("A7 outro simbolo suprime no repeteco", DiagGateAllow("EURUSD", "TESTE", "estado-B", 0), false);

   //--------------------------------------------- A8: tabela cheia
   // 300 chaves distintas com DIAG_GATE_MAX=256: as primeiras 256
   // entram, as restantes caem no limite. O contrato e LIBERTAR
   // sempre que a tabela esta cheia - nunca esconder journal por
   // falha do proprio portao.
   int permitidas = 0;
   for(int i = 0; i < 300; i++)
   {
      if(DiagGateAllow("S" + IntegerToString(i), "CHEIO", "x", 0))
         permitidas++;
   }
   Check("A8 tabela cheia liberta (300/300)", permitidas == 300, true);

   // A8b - depois de cheia, uma chave nova continua a sair.
   Check("A8b chave nova com tabela cheia sai", DiagGateAllow("NOVO", "CHEIO", "x", 0), true);

   //--------------------------------------------- A9: contabilidade
   // Suprimidas esperadas: A2, A4, A5, A7 = 4.
   Check("A9 contador de suprimidas == 4", g_diagGateSuppressed == 4, true);

   //--------------------------------------------- A10: resumo
   string s = DiagGateSummary();
   Print("[DIAGGATE-TEST] resumo -> ", s);
   Check("A10 resumo tem prefixo", StringFind(s, "[DIAGGATE]") == 0, true);
   Check("A10 resumo conta suprimidas", StringFind(s, "linhas suprimidas=4") > 0, true);

   //--------------------------------------------- C1..C4: CICLO (P1.25)
   // O defeito medido: SIGNAL_GENERATED -> VALIDATING -> RISK_CHECK -> ...
   // Cada aresta difere da anterior, logo o portao antigo libertava todas.
   Check("C1 ciclo aresta 1 sai",  DiagGateAllow("CICLO", "STATE", "A -> B", 14400), true);
   Check("C1 ciclo aresta 2 sai",  DiagGateAllow("CICLO", "STATE", "B -> C", 14400), true);
   Check("C1 ciclo aresta 3 sai",  DiagGateAllow("CICLO", "STATE", "C -> A", 14400), true);

   Check("C2 ciclo repetido suprime 1", DiagGateAllow("CICLO", "STATE", "A -> B", 14400), false);
   Check("C2 ciclo repetido suprime 2", DiagGateAllow("CICLO", "STATE", "B -> C", 14400), false);
   Check("C2 ciclo repetido suprime 3", DiagGateAllow("CICLO", "STATE", "C -> A", 14400), false);

   // C3 - 1000 voltas ao ciclo na mesma janela: nenhuma linha nova.
   int libertadas = 0;
   for(int volta = 0; volta < 1000; volta++)
   {
      if(DiagGateAllow("CICLO", "STATE", "A -> B", 14400)) libertadas++;
      if(DiagGateAllow("CICLO", "STATE", "B -> C", 14400)) libertadas++;
      if(DiagGateAllow("CICLO", "STATE", "C -> A", 14400)) libertadas++;
   }
   Check("C3 3000 repeticoes do ciclo -> 0 linhas", libertadas == 0, true);

   // C4 - aresta NOVA dentro da janela continua a sair (nada de esconder
   // sinal operacional por causa da memoria do ciclo).
   Check("C4 aresta nova na mesma janela sai", DiagGateAllow("CICLO", "STATE", "C -> EXECUTION_READY", 14400), true);

   //--------------------------------------------- veredicto
   Print("[DIAGGATE-TEST] fim | chaves=", g_diagGateCount,
         " | suprimidas=", g_diagGateSuppressed,
         " | falhas=", g_falhas,
         " | ", (g_falhas == 0 ? "APROVADO" : "REPROVADO"));
}
//+------------------------------------------------------------------+
