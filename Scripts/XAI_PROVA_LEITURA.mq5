//+------------------------------------------------------------------+
//| XAI_PROVA_LEITURA.mq5                                            |
//| P1.59 (v1.2.73) - prova negativa da leitura de ficheiro.         |
//| Comprova, no terminal a serio, o que a leitura em modo TEXTO     |
//| devolve para Data\prediction_XAUUSD.json e o que a leitura em    |
//| modo BINARIO devolve para o MESMO ficheiro.                      |
//| Script de prova: nao opera, nao altera nada, nao escreve ficheiro.|
//+------------------------------------------------------------------+
#property script_show_inputs

input string ArquivoProva = "Data\\prediction_XAUUSD.json";

//--- leitura ANTIGA: FILE_TXT | FILE_ANSI + FileReadString(tamanho)
string LeituraTexto(const string nome)
{
   int h = FileOpen(nome, FILE_READ | FILE_TXT | FILE_ANSI |
                    FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(h == INVALID_HANDLE)
      return "<HANDLE INVALIDO>";

   string out = "";
   ulong tam = FileSize(h);
   if(tam > 0)
      out = FileReadString(h, (int)MathMin(tam, 65536));

   FileClose(h);
   return out;
}

//--- leitura NOVA: FILE_BIN + FileReadArray + CharArrayToString
string LeituraBinaria(const string nome)
{
   int h = FileOpen(nome, FILE_READ | FILE_BIN |
                    FILE_SHARE_READ | FILE_SHARE_WRITE);
   if(h == INVALID_HANDLE)
      return "<HANDLE INVALIDO>";

   ulong tam = FileSize(h);
   if(tam == 0)
   {
      FileClose(h);
      return "";
   }

   int quer = (int)MathMin(tam, 65536);
   uchar buf[];
   ArrayResize(buf, quer);

   int lidos = (int)FileReadArray(h, buf, 0, quer);
   FileClose(h);

   if(lidos <= 0)
      return "";

   return CharArrayToString(buf, 0, lidos, CP_UTF8);
}

void Descrever(const string rotulo, const string s)
{
   Print(rotulo,
         " | len=", StringLen(s),
         " | abre=", (StringFind(s, "{") >= 0 ? "SIM" : "NAO"),
         " | fecha=", (StringFind(s, "}") >= 0 ? "SIM" : "NAO"),
         " | inicio=[", StringSubstr(s, 0, 24), "]");
}

void OnStart()
{
   Print("=== P1.59 PROVA DE LEITURA | arquivo=", ArquivoProva, " ===");

   uint ini = GetTickCount();
   string texto = LeituraTexto(ArquivoProva);
   uint tTexto = GetTickCount() - ini;

   ini = GetTickCount();
   string binario = LeituraBinaria(ArquivoProva);
   uint tBin = GetTickCount() - ini;

   Descrever("TEXTO  ", texto);
   Descrever("BINARIO", binario);

   Print("tempo texto=", tTexto, " ms | tempo binario=", tBin, " ms");
   Print("iguais=", (texto == binario ? "SIM" : "NAO"));
   Print("=== FIM DA PROVA ===");
}
//+------------------------------------------------------------------+
