//+------------------------------------------------------------------+
//|                                                      Bot Ciclo C |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+


// Inclui os arquivos necessários para acessar funções de negociação e informações da conta
#include <Trade\Trade.mqh>
#include <Trade\AccountInfo.mqh>

// Declaração de variáveis globais
CAccountInfo m_account; // Objeto para acessar informações da conta
CTrade trade; // Objeto para executar operações de negociação
MqlRates rates[]; // Array para armazenar dados históricos de preço
MqlDateTime mqlDateTime; // Variável para armazenar data e hora
MqlTick ultimoTick; // Estrutura para armazenar informações de tick

// Parâmetros de entrada
input double gain = 0.4; // Ganho desejado para o trailing stop
input double loss = 0.4; // Perda desejada para o trailing stop
input bool usar_trailing = true; // Habilita o trailing stop
input double InpTrailingStopPoints = 0.00025; // Distância para o trailing stop em pontos
input bool usar_break_even_troca_canal = true; // Habilita o ajuste do stop loss para o ponto de entrada após a mudança de canal
input bool habilitar_operacao_troca_canal = true; // Habilita a operação após a mudança de canal
input double porcentagem_adiantamento_compra = 0.05; // Porcentagem de adiantamento para compra após a mudança de canal
input double porcentagem_adiantamento_venda = 0.05; // Porcentagem de adiantamento para venda após a mudança de canal
input bool habilitar_retoque_apos_completar_canal = false; // Habilita o retracement após completar o canal
input int permitir_quantidade_toques = 1; // Número máximo de toques permitidos no canal
input bool fazer_gale = true; // Habilita a estratégia de Martingale
input int qnt_fazer_gale = 10; // Número máximo de tentativas de Martingale
input int magic_number_a = 159753; // Número mágico para identificar as ordens
input string comentario_ordem = "Ordem por Ciclo C"; // Comentário para identificar as ordens
input int periodo_indicador = 20; // Período do indicador personalizado
input double sensibilidade_indicador = 1.5; // Sensibilidade do indicador personalizado
input double lote_conta = 0.1; // Tamanho do lote baseado no saldo da conta
input bool lote_fixo = true; // Indica se o tamanho do lote é fixo ou baseado no saldo da conta
input int risco_conta = 1; // Porcentagem do saldo da conta arriscado por operação

double lote; // Variável para armazenar o tamanho do lote calculado

// Função OnInit: Executada uma vez quando o EA é iniciado
int OnInit()
{
    // Obtém o saldo da conta
    double saldo_conta = m_account.Balance();
    // Define o número mágico do EA
    trade.SetExpertMagicNumber(magic_number_a);
    // Calcula o tamanho do lote com base no saldo da conta e no risco especificado
    int multiplicador_saldo = int(saldo_conta / 100);
    lote = (multiplicador_saldo * 0.01) * risco_conta;

    // Chama o indicador personalizado e imprime o resultado e erros
    ResetLastError();
    CICLO = iCustom(NULL, 0, "CICLO_C", periodo_indicador, sensibilidade_indicador);
    Print("CICLO =", CICLO, "  error =", GetLastError());
    ResetLastError();
    return (0);
}

// Função OnTick: Executada a cada tick
void OnTick()
{
    // Declaração e inicialização de variáveis locais
    double ask, bid, last;
    double saldo_conta = m_account.Balance();

    // Obtém os preços atuais do símbolo
    ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
    bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
    last = SymbolInfoDouble(_Symbol, SYMBOL_LAST);

    // Obtém os dados históricos de preço
    ArraySetAsSeries(rates, true);
    CopyRates(_Symbol, _Period, 0, 10, rates);

    // Obtém a data e hora atual
    TimeCurrent(mqlDateTime);
    int hora = mqlDateTime.hour;
    int min = mqlDateTime.min;

    // Declaração e inicialização de arrays para armazenar os valores do indicador personalizado
    double _Ciclo_Compra[];
    double _Ciclo_Venda[];
    ArraySetAsSeries(_Ciclo_Compra, true);
    ArraySetAsSeries(_Ciclo_Venda, true);
    CopyBuffer(CICLO, 0, 0, 5, _Ciclo_Compra);
    CopyBuffer(CICLO, 1, 0, 5, _Ciclo_Venda);

   
if(hora < 23 && hora > 2)
     {
      double distancia = _Ciclo_Venda[0] - _Ciclo_Compra[0];

      ExisteOrdem = false;
      ChecarOrdem(Symbol(), magic_number_a);
      if(ExisteOrdem == true && canal_trocado == true && habilitar_operacao_troca_canal == true)
        {
         ExisteOrdem = false;
        }

      if(usar_trailing == true)
        {
         ApplyTrailingStop(Symbol(), magic_number_a, InpTrailingStopPoints);
        }

      if(ExisteOrdem == false && rates[0].open != open && rates[0].close >= _Ciclo_Venda[0] - (distancia * porcentagem_adiantamento_venda) && emVenda == false && contVenda < permitir_quantidade_toques)
        {
         double preco = ask;
         contVenda ++;
         contCompra = 0;
         cont_Op++;

         if(fazer_gale == true)
           {
            if(cont_gale < qnt_fazer_gale)
              {
               if(saldo_conta < saldo_conta_na_op)
                 {                  
                  lote = lote *2;
                  if(lote > 95)
                  {
                     lote = 95;
                  }
                  cont_gale++;
                 }
               else
                 {
                  cont_gale = 0;
                  if(lote_fixo == false)
                    {
                     int multiplicador_saldo = int(saldo_conta / 100);
                     lote = (multiplicador_saldo * 0.01) * risco_conta;
                    }
                  else
                    {
                     lote = lote_conta;
                    }
                 }
              }
           }

         saldo_conta_na_op = saldo_conta;

         open = rates[0].open;
         double ga = (distancia * gain);
         double lo = (distancia * loss);
         trade.Sell(lote, NULL, preco, preco + lo, preco - ga, comentario_ordem);         
         emVenda = true;
         if(habilitar_retoque_apos_completar_canal == true)
           {
            emCompra = false;
           }
         canal_trocado = false;
         linha_ant_venda = _Ciclo_Venda[0];
        }

      if(ExisteOrdem == false && rates[0].open != open && rates[0].close <= _Ciclo_Compra[0] + (distancia * porcentagem_adiantamento_compra) && emCompra == false && contCompra < permitir_quantidade_toques)
        {
         double preco = bid;
         contCompra ++;
         contVenda = 0;
         cont_Op++;

         if(fazer_gale == true)
           {
            if(cont_gale < qnt_fazer_gale)
              {
               if(saldo_conta < saldo_conta_na_op)
                 {
                  lote = lote *2;
                  if(lote > 95)
                  {
                     lote = 95;
                  }
                  cont_gale++;
                 }
               else
                 {
                  cont_gale = 0;
                  if(lote_fixo == false)
                    {
                     int multiplicador_saldo = int(saldo_conta / 100);
                     lote = (multiplicador_saldo * 0.01) * risco_conta;
                    }
                  else
                    {
                     lote = lote_conta;
                    }
                 }
              }
           }

         saldo_conta_na_op = saldo_conta;

         open = rates[0].open;
         double ga = (distancia * gain);
         double lo = (distancia * loss);

         trade.Buy(lote, NULL, preco, preco - lo, preco + ga, comentario_ordem);         
         if(habilitar_retoque_apos_completar_canal == true)
           {
            emVenda = false;
           }
         emCompra = true;
         canal_trocado = false;
         linha_ant_compra = _Ciclo_Compra[0];
        }
     }

   if(tempo < rates[0].time)
     {
      tempo = rates[0].time;

      if(ExisteOrdem == false)
        {
         if(emCompra == true && contCompra < permitir_quantidade_toques)
           {
            emCompra = false;
           }
         if(emVenda == true && contVenda < permitir_quantidade_toques)
           {
            emVenda = false;
           }
        }

      if(linha_ant_venda != _Ciclo_Venda[0] || linha_ant_compra != _Ciclo_Compra[0])
        {
         linha_ant_compra = _Ciclo_Compra[0];
         linha_ant_venda = _Ciclo_Venda[0];
         emCompra = false;
         emVenda = false;
         canal_trocado = true;
         contCompra = 0;
         contVenda = 0;

         if(usar_break_even_troca_canal == true)
           {
            if(ExisteOrdem == true)
              {
               BreakEven(Symbol(), magic_number_a);
              }
           }
        }
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+



// Função ApplyTrailingStop: Aplica o trailing stop para as ordens existentes
void ApplyTrailingStop(string symbol, int magicNumber, double stopLoss)
{
    // Obtém o número de dígitos após o ponto decimal do preço
    static int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    // Calcula o novo nível de stop loss para as ordens
    double buyStopLoss = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_BID) - stopLoss, digits);
    double sellStopLoss = NormalizeDouble(SymbolInfoDouble(symbol, SYMBOL_ASK) + stopLoss, digits);
    int count = PositionsTotal();
    // Percorre todas as ordens abertas
    for (int i = count - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0)
        {
            if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magicNumber)
            {
                if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY && buyStopLoss > PositionGetDouble(POSITION_PRICE_OPEN) && (PositionGetDouble(POSITION_SL) == 0 || buyStopLoss > PositionGetDouble(POSITION_SL)))
                {
                    trade.PositionModify(ticket, buyStopLoss, PositionGetDouble(POSITION_TP));
                }
                else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL && sellStopLoss < PositionGetDouble(POSITION_PRICE_OPEN) && (PositionGetDouble(POSITION_SL) == 0 || sellStopLoss < PositionGetDouble(POSITION_SL)))
                {
                    trade.PositionModify(ticket, sellStopLoss, PositionGetDouble(POSITION_TP));
                }
            }
        }
    }
}

// Função BreakEven: Ajusta o stop loss para o ponto de entrada após a mudança de canal
void BreakEven(string symbol, int magicNumber)
{
    // Obtém o número de dígitos após o ponto decimal do preço
    static int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    int count = PositionsTotal();
    double PrecoEntrada = PositionGetDouble(POSITION_PRICE_OPEN);
    // Percorre todas as ordens abertas
    for (int i = count - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0)
        {
            trade.PositionModify(ticket, PositionGetDouble(POSITION_SL), PrecoEntrada);
        }
    }
}

// Função ChecarOrdem: Verifica se há alguma ordem aberta com o número mágico especificado
void ChecarOrdem(string symbol, int magicNumber)
{
    // Obtém o número de dígitos após o ponto decimal do preço
    static int digits = (int)SymbolInfoInteger(symbol, SYMBOL_DIGITS);
    int count = PositionsTotal();
    // Percorre todas as ordens abertas
    for (int i = count - 1; i >= 0; i--)
    {
        ulong ticket = PositionGetTicket(i);
        if (ticket > 0)
        {
            if (PositionGetString(POSITION_SYMBOL) == symbol && PositionGetInteger(POSITION_MAGIC) == magicNumber)
            {
                ExisteOrdem = true;
            }
        }
    }
}
