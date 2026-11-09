<chart>
id=0
symbol=XAUUSD
description=Gold vs US Dollar
period_type=1
period_size=1
digits=2
tick_size=0.010000
position_time=1793962800
scale_fix=0
scale_fixed_min=4000.570000
scale_fixed_max=4113.400000
scale_fix11=0
scale_bar=0
scale_bar_val=1.000000
scale=16
mode=1
fore=0
grid=1
volume=1
scroll=1
shift=0
shift_size=21.951220
fixed_pos=0.000000
ticker=1
ohlc=0
one_click=0
one_click_btn=1
bidline=1
askline=0
lastline=0
days=0
descriptions=0
tradelines=1
tradehistory=1
window_left=0
window_top=0
window_right=272
window_bottom=100
window_type=1
floating=0
floating_left=0
floating_top=0
floating_right=0
floating_bottom=0
floating_type=1
floating_toolbar=1
floating_tbstate=
background_color=0
foreground_color=16777215
barup_color=65280
bardown_color=65280
bullcandle_color=0
bearcandle_color=16777215
chartline_color=65280
volumes_color=3329330
grid_color=10061943
bidline_color=10061943
askline_color=255
lastline_color=49152
stops_color=255
windows_total=1

<expert>
name=XAU_AI_PRO
path=Experts\XAU_AI_PRO\XAU_AI_PRO.ex5
expertmode=5
<inputs>
AutoTrade=true
MagicNumber=2026001
TradeComment=XAU_AI_PRO
AIUseGateway=true
AIGatewayUrl=http://127.0.0.1:9011/api/ai/predict
AIGatewayToken=
AIPollSeconds=15
AIRequestTimeoutMs=15000
EnableExternalBridge=false
ExternalBridgeToken=
EnableMCPServer=false
MCPServerToken=
RiskPercent=0.5
MaxDailyLossPercent=3.0
MaxDailyLossUsd=60.0
MaxDrawdownPercent=6.0
MinEquityPercent=10.0
MinFreeMargin=10.0
MaxTradesPerDay=100
MaxOpenPositions=50
EnableExposureCap=true
MaxExposurePercent=20.0
AllowMinLotOverride=true
MaxSpreadPct=0.6
MaxSpreadPctBySymbol=
Slippage=5
RetryMaxAttempts=5
RetryBaseDelayMs=100
RetryDelayMultiplier=2.0
RetryMaxDelayMs=2000
RetryMaxSlippage=50
RetrySlippageIncrement=2
StopLossPoints=300
TakeProfitPoints=600
RiskPerTradeUsd=2.0
RewardRatio=0.65
RiskPerTradePercent=0.5
MaxTotalRiskPercent=10.0
MaxTotalRiskOpenUsd=60.0
EnableBreakEven=true
BreakEvenTrigger=50
BreakEvenOffset=10
BreakEvenInR=true
BreakEvenTriggerR=0.6
BreakEvenLockR=0.3
EnableMoneyLadder=true
LadderArmUsd=5.0
LadderLockUsd=1.0
LadderLockTriggerUsd=7.0
LadderTpUsd=10.0
EnableOperatorBrief=true
OperatorBriefSeconds=300
EnableTrailingATR=true
ATRMultiplier=1.2
EnablePartialClose=true
PartialTrigger=150
PartialPercent=30.0
PartialTriggerInATR=true
PartialTriggerATRMult=1.0
EnableDynamicTP=true
TPAproxStepATRMult=1.0
TPAproxMaxFraction=1.0
EnableSpreadFilter=true
EnableSessionFilter=false
EnableTrendFilter=true
EnableVolatilityFilter=false
EnableADXFilter=true
EnableMTFConfirmation=false
EnableNewsFilter=false
EnableAIFilter=true
EnableStaleDataGuard=true
MaxSymbolTickAgeSec=900
NewsCurrencies=
NewsImpactThreshold=2
NewsMinutesBefore=30
NewsMinutesAfter=30
EnableNewsTrading=true
NewsTradeMode=1
NewsTradeMinImpact=3
NewsTradeLotFactor=0.35
NewsTradeRiskMult=1.6
NewsTradeTPMult=1.3
NewsTradeMinConf=70.0
NewsTradeTrendOnly=true
NewsTrendMinADX=18.0
EnableMarketPulse=true
PulseVolumeLookback=20
PulseVolumeSpikeMult=1.8
PulseVelocityBars=3
PulseVelocityATRMult=0.6
PulseExtremeFactor=1.8
PulseFastArmFactor=0.5
PulseFastLockFactor=0.8
PulseFastLotFactor=0.8
PulseQuickProfitMinUsd=10.0
PulseQuickProfitBalancePct=3.0
PulseQuickLossUsd=12.0
PulseQuickProfitMaxUsd=50.0
PulseFastLaneSec=5
MinSimulationRR=0.3
MinSimulationExpectancy=0.0
MinSimulationProbability=0.5
SimulationUseConfidence=true
MinAIConfidence=60.0
AllowTradeWithoutAI=true
EnableAIConflictResolve=true
AIConflictMinScore=80.0
AIUnavailableConfidenceCap=40.0
AIHasSignalAuthority=false
AIAuthorityMinScore=75.0
EnableMarketIntelligence=true
MinIntelligenceScore=0.0
BlockPreCloseMinutes=15
BlockHighImpactNewsMin=15
LowIntelLotFactor=0.5
RequireAIJSON=false
RequireStopLoss=true
MaxPredictionAgeSec=900
KCI_VD_Period=14
KCI_DX_BasePeriod=9
KCI_DX_ZScorePeriod=30
KCI_DX_Sensitivity=1.5
KCI_DX_MainThreshold=30.0
TradeStartHour=0
TradeEndHour=24
AvoidHoursList=0,20
EnableAvoidHoursGMT=true
AvoidHoursGMT=9,11,14,18,20,22
AvoidHoursByClass=
EnableCostGate=true
MaxCostPctOfTarget=20.0
MaxCostPctOfRisk=40.0
CommissionPerLotUsd=0.0
CostGateLogSec=300
FastEMA=50
SlowEMA=200
RSIPeriod=14
RSIPullbackBuy=45.0
RSIPullbackSell=55.0
ATRPeriod=14
ADXPeriod=14
MinimumADX=18.0
EnableScheduler=true
SchedulerIntervalSec=60
EnableWeekendShutdown=true
EnableDatabase=false
DatabasePath=XAU_AI_PRO.db
EnableTelemetry=true
EnableDataset=true
SaveDatasetCSV=true
EnableBacktestLog=true
EnableDashboard=true
EnableLogs=true
DebugTradeDecision=true
EnableHealthMonitor=true
HealthCheckInterval=60
HealthWatchdogInterval=120
HealthPipelineProgressTimeout=0
EnableAuditLog=true
AuditLogMaxSizeMb=8
EnableDiagnostics=true
EnableReplay=false
ReplayDatasetFile=Data\trades_dataset.csv
ReplayOHLCFile=Data\dataset.csv
ReplayAuditFile=Data\full_audit.csv
ReplaySymbolFilter=
EnableBackupManager=true
BackupIntervalMinutes=60
BackupMaxKeep=10
EnableBacktestAnalyzer=true
EnableBenchmark=true
EnableNotifications=true
NotifyPushEnabled=true
NotifyTelegramToken=
NotifyTelegramChatID=
NotifyCooldownSec=30
NotifyMaxPerMinute=10
NotifyTradeEvents=true
NotifyErrors=true
NotifyDrawdown=true
NotifyDrawdownThreshold=5.0
NotifyHealth=true
NotifyCircuitBreaker=true
NotifyExecutionFailures=true
EnableMultiSymbol=true
Symbols=XAUUSD,EURUSD,GBPUSD,USDJPY,AUDUSD,USDCAD,NZDUSD,USDCHF,USDBRL,USDSEK,USDCNH
SymbolsFromMarketWatch=false
MaxTradeRiskPctOfBudget=100.0
EnableAutonomousMode=true
MinMarketScore=65.0
MinMarketScoreNoAI=45.0
BlockZeroAIScore=true
EnableStoplessEntry=true
StoplessArmATRMult=0.8
StoplessArmMinPoints=30
StoplessLockATRMult=0.35
StoplessLockMinPoints=10
StoplessEmergencyPoints=0
StoplessEmergencyRMult=1.5
EnableAdaptiveTargets=true
DynTPFactorMin=0.35
DynTPFactorBase=0.5
DynTPFactorClear=0.8
DynTPFactorStrong=1.2
DynTPFactorElite=2.0
MinTargetPoints=70
MaxTargetPoints=1500
EnableDynamicLot=true
DynLotFactorMin=0.25
DynLotFactorBase=1.0
DynLotFactorClear=2.0
DynLotFactorStrong=3.0
DynLotFactorElite=4.0
DynConfBase=66.0
DynConfClear=74.0
DynConfStrong=82.0
DynConfElite=90.0
DynADXClear=35.0
DynADXStrong=35.0
MaxRiskPerTradePercentCap=3.0
MaxRiskPerTradeUsd=8.0
BlockWhenMinLotExceedsRiskCap=true
EnableScenarioAdaptation=true
EnableAdaptiveTrendGate=true
EnableScenarioLog=true
ScenarioADXStrong=25.0
ScenarioADXWeak=18.0
ScenarioCounterTrendMaxADX=22.0
ScenarioTrendAtrSlack=1.0
ScenarioVolPctMax=2.0
ScenarioLotStrong=1.0
ScenarioLotWeak=0.9
ScenarioLotRanging=0.75
ScenarioLotVolatile=0.6
ScenarioTargetVolatile=1.15
ScenarioTargetRanging=0.9
EnableCurrencyExposureGuard=true
MaxCorrelatedTrades=3
MaxCorrelatedRiskPercent=3.0
EnableSessionLotAdaptation=true
SessionLotAsia=0.85
SessionLotLondon=1.0
SessionLotNY=1.0
SessionLotLate=0.7
SessionLotClosed=0.5
SessionLotExoticOffHours=0.75
SessionLotFloor=0.35
EnableGlobalScenarioLog=true
EnableDailyProfitTarget=true
DailyProfitTargetUsd=20.0
EnableDailyTargetBalancePct=true
DailyProfitTargetBalancePct=10.0
DailyProfitTargetMaxUsd=40.0
DailyProfitSlowPercent=100.0
DailyProfitStopTrading=true
DailyProfitSlowLotFactor=0.25
DailyProfitProtectPositions=true
EnablePipelineMasterGuard=true
EnableStreakBrake=true
StreakBrakeLosses=3
StreakBrakePauseMinutes=240
EnableVerboseDebug=true
TrendTF=16385
CircuitAbnormalMarketBlocksAll=false
CircuitAbnormalATRRatio=3.0
CircuitBrokerFailMinCheck=3
CircuitBrokerFailMinSeconds=15
CircuitWarmupSeconds=30
EnableRealAccountGuard=true
RealGuardBlockMinLotExceedsCap=true
RealGuardStoplessEmergencyRMultFloor=1.5
RealGuardMaxUnarmedPositions=1
ConfirmTF1=15
MTF_FastEMA=20
MTF_SlowEMA=50
MTFUseClosedCandle=true
=== APRENDIZADO PELO HISTORICO ====
EnableLearningFromHistory=true
LearningImportManualTrades=true
LearningImportExpertTrades=true
LearningHistoryDays=180
EnableLearningBoost=true
LearningPenaltyEnabled=false
LearningDirBoostEnabled=true
LearningDirMinTrades=3
EnableLearningHourBoost=true
LearningHourMinTrades=4
EnableDirectionBlacklist=false
DirectionBlacklistMinTrades=5
DirectionBlacklistMaxWR=30.0
EnableLearningLotPenalty=true
LearningPenaltyMinTrades=5
LearningPenaltyMaxWR=40.0
LearningPenaltyLotFactor=0.6
LearningPenaltyHardWR=25.0
LearningPenaltyHardLotFactor=0.45
EnableLearningHourPenalty=true
LearningPenaltyHourLotFactor=0.75
EnableLearningHourScorePenalty=true
LearningHourScoreFloor=0.9
EnableSessionStatePersistence=true
SignalCoreVersion=0
V2_TrendTF=16385
V2_TrendFastEMA=50
V2_TrendSlowEMA=200
V2_EntryTF=15
V2_RangeLookback=16
V2_MinRangePoints=80
V2_UseSessionWindow=true
V2_SessionStartHour=13
V2_SessionEndHour=21
V2_LevelMode=0
V2_RequireTrend=true
V2_RequireRSI=false
V2_RSIPeriod=14
V2_RSIMinConf=50.0
V2_LogSignals=true
EnableManualExposureGuard=true
ManualGuardAllowSameDirection=false
MinRewardRatio=0.55
EffectiveRiskWarnFactor=1.5
MinSecondsBetweenTradesPerSymbol=300
EnableForwardLog=true
ForwardHeartbeatSec=300
</inputs>
</expert>

<window>
height=100.000000
objects=187

<indicator>
name=Main
path=
apply=1
show_data=1
scale_inherit=0
scale_line=0
scale_line_percent=50
scale_line_value=0.000000
scale_fix_min=0
scale_fix_min_val=0.000000
scale_fix_max=0
scale_fix_max_val=0.000000
expertmode=1
fixed_height=-1
</indicator>
<object>
type=109
name=2026.10.26 14:30 Índice de Atividade Nacional Chicago Fed
hidden=1
descr=Índice de Atividade Nacional Chicago Fed 0.07 / 0.04
color=15658671
selectable=0
date1=1793025000
</object>

<object>
type=109
name=2026.10.26 16:30 Índice de Atividade Industrial do Fed de Dalas
hidden=1
descr=Índice de Atividade Industrial do Fed de Dalas 13.4 / 6.4
color=15658671
selectable=0
date1=1793032200
</object>

<object>
type=109
name=2026.10.26 17:30 Leilão Bill a 3 meses
hidden=1
descr=Leilão Bill a 3 meses
color=16119285
selectable=0
date1=1793035800
</object>

<object>
type=109
name=2026.10.26 17:30 Leilão Bill a 6 meses
hidden=1
descr=Leilão Bill a 6 meses
color=16119285
selectable=0
date1=1793035800
</object>

<object>
type=109
name=2026.10.26 19:00 Leilão Note a 2 anos
hidden=1
descr=Leilão Note a 2 anos
color=16119285
selectable=0
date1=1793041200
</object>

<object>
type=109
name=2026.10.27 14:30 Pedidos de Bens Duráveis (Mensal)
hidden=1
descr=Pedidos de Bens Duráveis (Mensal) 0.5% / 1.0%
color=13353215
selectable=0
date1=1793111400
</object>

<object>
type=109
name=2026.10.27 14:30 Pedidos de Bens Duráveis ​​Excluindo o Setor d
hidden=1
descr=Pedidos de Bens Duráveis ​​Excluindo o Setor de Defesa (Mensal)
color=15658671
selectable=0
date1=1793111400
</object>

<object>
type=109
name=2026.10.27 14:30 Núcleo de Encomendas de Bens de Capital (fora 
hidden=1
descr=Núcleo de Encomendas de Bens de Capital (fora do setor de Defes
color=13353215
selectable=0
date1=1793111400
</object>

<object>
type=109
name=2026.10.27 14:30 Encomendas de Bens de Capital (fora do setor d
hidden=1
descr=Encomendas de Bens de Capital (fora do setor de Defesa e exclui
color=15658671
selectable=0
date1=1793111400
</object>

<object>
type=109
name=2026.10.27 15:00 Índice de Preços de Imóveis (Mensal)
hidden=1
descr=Índice de Preços de Imóveis (Mensal) 0.3% / 0.1%
color=15658671
selectable=0
date1=1793113200
</object>

<object>
type=109
name=2026.10.27 15:00 Índice de Preços de Imóveis (Anual)
hidden=1
descr=Índice de Preços de Imóveis (Anual) 2.4% / 2.6%
color=13353215
selectable=0
date1=1793113200
</object>

<object>
type=109
name=2026.10.27 15:00 Índice de Preços de Imóveis
hidden=1
descr=Índice de Preços de Imóveis 444.6 / 444.4
color=15658671
selectable=0
date1=1793113200
</object>

<object>
type=109
name=2026.10.27 15:00 Preços de Imóveis S&P/CS Composto-20 (Anual)
hidden=1
descr=Preços de Imóveis S&P/CS Composto-20 (Anual)
color=16119285
selectable=0
date1=1793113200
</object>

<object>
type=109
name=2026.10.27 15:00 Preços de Imóveis S&P/CS Composto-20 sem ajust
hidden=1
descr=Preços de Imóveis S&P/CS Composto-20 sem ajuste sazonal  (Mensa
color=16119285
selectable=0
date1=1793113200
</object>

<object>
type=109
name=2026.10.27 15:00 Preços de Imóveis S&P/CS Composto-20 com ajust
hidden=1
descr=Preços de Imóveis S&P/CS Composto-20 com ajuste sazonal  (Mensa
color=16119285
selectable=0
date1=1793113200
</object>

<object>
type=109
name=2026.10.27 16:00 Venda de Casas Novas
hidden=1
descr=Venda de Casas Novas 0.676 M / 0.708 M
color=13353215
selectable=0
date1=1793116800
</object>

<object>
type=109
name=2026.10.27 16:00 Venda de Casas Novas (Mensal)
hidden=1
descr=Venda de Casas Novas (Mensal) -0.6% / -1.4%
color=15658671
selectable=0
date1=1793116800
</object>

<object>
type=109
name=2026.10.27 16:00 EUA - Confiança do Consumidor Conference Board
hidden=1
descr=EUA - Confiança do Consumidor Conference Board (CB) 91.7 / 81.5
color=15658671
selectable=0
date1=1793116800
</object>

<object>
type=109
name=2026.10.27 16:00 Índice de Manufatura do Fed de Richmond
hidden=1
descr=Índice de Manufatura do Fed de Richmond -2 / -1
color=13353215
selectable=0
date1=1793116800
</object>

<object>
type=109
name=2026.10.27 16:00 Índice de Embarques do Setor Industrial Richmo
hidden=1
descr=Índice de Embarques do Setor Industrial Richmond
color=16119285
selectable=0
date1=1793116800
</object>

<object>
type=109
name=2026.10.27 16:00 Índice do Setor de Serviços de Richmond
hidden=1
descr=Índice do Setor de Serviços de Richmond 2 / -3
color=15658671
selectable=0
date1=1793116800
</object>

<object>
type=109
name=2026.10.27 16:30 Subíndice de Receita com Serviços do Fed de Da
hidden=1
descr=Subíndice de Receita com Serviços do Fed de Dallas 4.4 / 5.4
color=13353215
selectable=0
date1=1793118600
</object>

<object>
type=109
name=2026.10.27 16:30 Índice de Atividade das Empresas do Fed de Dal
hidden=1
descr=Índice de Atividade das Empresas do Fed de Dallas 4.0 / -2.9
color=15658671
selectable=0
date1=1793118600
</object>

<object>
type=109
name=2026.10.27 17:30 Leilão Bill a 52 semanas
hidden=1
descr=Leilão Bill a 52 semanas
color=16119285
selectable=0
date1=1793122200
</object>

<object>
type=109
name=2026.10.27 19:00 Leilão Note a 5 anos
hidden=1
descr=Leilão Note a 5 anos
color=16119285
selectable=0
date1=1793127600
</object>

<object>
type=109
name=2026.10.28 11:00 Índice de Expectativas Econômicas do Credit Su
hidden=1
descr=Índice de Expectativas Econômicas do Credit Suisse
color=16119285
selectable=0
date1=1793185200
</object>

<object>
type=109
name=2026.10.28 14:30 Estoques no Atacado (Mensal)
hidden=1
descr=Estoques no Atacado (Mensal) 0.6% / 1.3%
color=15658671
selectable=0
date1=1793197800
</object>

<object>
type=109
name=2026.10.28 14:30 Balança Comercial de Bens
hidden=1
descr=Balança Comercial de Bens $-134.904 B / $-114.307 B
color=13353215
selectable=0
date1=1793197800
</object>

<object>
type=109
name=2026.10.28 14:30 Estoques no Varejo (Mensal)
hidden=1
descr=Estoques no Varejo (Mensal) 0.3% / 0.4%
color=15658671
selectable=0
date1=1793197800
</object>

<object>
type=109
name=2026.10.28 14:30 Estoques no Varejo, excl. Automóveis
hidden=1
descr=Estoques no Varejo, excl. Automóveis
color=16119285
selectable=0
date1=1793197800
</object>

<object>
type=109
name=2026.10.28 16:30 EIA: Estoques de Petróleo Bruto
hidden=1
descr=EIA: Estoques de Petróleo Bruto -1.892 M / -2.067 M
color=13353215
selectable=0
date1=1793205000
</object>

<object>
type=109
name=2026.10.28 16:30 EIA: Estoques de Petróleo Bruto em Cushing
hidden=1
descr=EIA: Estoques de Petróleo Bruto em Cushing -0.624 M / -0.103 M
color=15658671
selectable=0
date1=1793205000
</object>

<object>
type=109
name=2026.10.28 16:30 EIA: Importações de Petróleo Bruto
hidden=1
descr=EIA: Importações de Petróleo Bruto -0.796 M / 0.216 M
color=15658671
selectable=0
date1=1793205000
</object>

<object>
type=109
name=2026.10.28 16:30 EIA: Estoques de Destilado
hidden=1
descr=EIA: Estoques de Destilado -0.071 M / 0.022 M
color=15658671
selectable=0
date1=1793205000
</object>

<object>
type=109
name=2026.10.28 16:30 EIA: Estoques de Destilado 
hidden=1
descr=EIA: Estoques de Destilado  -1.462 M / 1.393 M
color=15658671
selectable=0
date1=1793205000
</object>

<object>
type=109
name=2026.10.28 16:30 EIA: Produção de Gasolina
hidden=1
descr=EIA: Produção de Gasolina -0.509 M / -0.001 M
color=15658671
selectable=0
date1=1793205000
</object>

<object>
type=109
name=2026.10.28 16:30 EIA: Óleo de Aquecimento
hidden=1
descr=EIA: Óleo de Aquecimento 0.164 M / 0.001 M
color=13353215
selectable=0
date1=1793205000
</object>

<object>
type=109
name=2026.10.28 16:30 EIA: Estoques de Gasolina
hidden=1
descr=EIA: Estoques de Gasolina 3.870 M / 0.125 M
color=13353215
selectable=0
date1=1793205000
</object>

<object>
type=109
name=2026.10.28 16:30 Fornecimento Diário de Petróleo de Refinarias 
hidden=1
descr=Fornecimento Diário de Petróleo de Refinarias da EIA
color=16119285
selectable=0
date1=1793205000
</object>

<object>
type=109
name=2026.10.28 16:30 Taxa de Utilização de Refinarias da EIA 
hidden=1
descr=Taxa de Utilização de Refinarias da EIA 
color=16119285
selectable=0
date1=1793205000
</object>

<object>
type=109
name=2026.10.28 20:00 Declaração da Reunião do FOMC 
hidden=1
descr=Declaração da Reunião do FOMC 
color=16119285
selectable=0
date1=1793217600
</object>

<object>
type=109
name=2026.10.28 20:00 Taxa-alvo de Fundos da Reserva Federal (Fed)
hidden=1
descr=Taxa-alvo de Fundos da Reserva Federal (Fed)
color=16119285
selectable=0
date1=1793217600
</object>

<object>
type=109
name=2026.10.28 20:30 Coletiva de Imprensa do Comitê Federal de Merc
hidden=1
descr=Coletiva de Imprensa do Comitê Federal de Mercado Aberto
color=16119285
selectable=0
date1=1793219400
</object>

<object>
type=109
name=2026.10.29 14:30 Núcleo do Índice de Preços das Despesas de Con
hidden=1
descr=Núcleo do Índice de Preços das Despesas de Consumo Pessoal (PCE
color=13353215
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 Índice de Preços das Despesas de Consumo Pesso
hidden=1
descr=Índice de Preços das Despesas de Consumo Pessoal (PCE) (Trimest
color=13353215
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 Gastos Pessoais (Mensal)
hidden=1
descr=Gastos Pessoais (Mensal) 0.5% / 0.9%
color=13353215
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 Renda Pessoal (Mensal)
hidden=1
descr=Renda Pessoal (Mensal) 0.2% / 0.3%
color=13353215
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 PIB (Trimestral)
hidden=1
descr=PIB (Trimestral) 3.4% / 1.4%
color=15658671
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 Deflator Implícito do Produto Interno Bruto (P
hidden=1
descr=Deflator Implícito do Produto Interno Bruto (PIB) (Trimestral) 
color=13353215
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 Consumo Pessoal Real (Mensal)
hidden=1
descr=Consumo Pessoal Real (Mensal) 0.0% / 0.1%
color=13353215
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 Consumo Pessoal Real (Trimestral)
hidden=1
descr=Consumo Pessoal Real (Trimestral) 3.8% / 3.5%
color=15658671
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 Produto Interno Bruto (PIB) Vendas (Trimestral
hidden=1
descr=Produto Interno Bruto (PIB) Vendas (Trimestral) 1.7% / 2.7%
color=13353215
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 Pedidos Iniciais de Subsídio de Desemprego
hidden=1
descr=Pedidos Iniciais de Subsídio de Desemprego
color=16119285
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 Pedidos Contínuos de Subsídio de Desemprego
hidden=1
descr=Pedidos Contínuos de Subsídio de Desemprego
color=16119285
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 14:30 Pedidos Iniciais por Seguro-Desemprego para 4 
hidden=1
descr=Pedidos Iniciais por Seguro-Desemprego para 4 semanas
color=16119285
selectable=0
date1=1793284200
</object>

<object>
type=109
name=2026.10.29 16:00 Índice de Preços das Despesas de Consumo Pesso
hidden=1
descr=Índice de Preços das Despesas de Consumo Pessoal (PCE) do Fed d
color=16119285
selectable=0
date1=1793289600
</object>

<object>
type=109
name=2026.10.29 16:30 EIA: Estoques de Gás Natural
hidden=1
descr=EIA: Estoques de Gás Natural 80 B / 79 B
color=13353215
selectable=0
date1=1793291400
</object>

<object>
type=109
name=2026.10.29 17:30 Leilão Bill a 4 semanas
hidden=1
descr=Leilão Bill a 4 semanas
color=16119285
selectable=0
date1=1793295000
</object>

<object>
type=109
name=2026.10.29 17:30 Leilão Bill a 8 semanas
hidden=1
descr=Leilão Bill a 8 semanas
color=16119285
selectable=0
date1=1793295000
</object>

<object>
type=109
name=2026.10.29 19:00 Leilão Note a 7 anos
hidden=1
descr=Leilão Note a 7 anos
color=16119285
selectable=0
date1=1793300400
</object>

<object>
type=109
name=2026.10.30 10:00 Indicador de Perspectivas Econômicas do Instit
hidden=1
descr=Indicador de Perspectivas Econômicas do Instituto KOF
color=16119285
selectable=0
date1=1793354400
</object>

<object>
type=109
name=2026.10.30 14:30 Índice do Custo do Emprego (Trimestral)
hidden=1
descr=Índice do Custo do Emprego (Trimestral)
color=16119285
selectable=0
date1=1793370600
</object>

<object>
type=109
name=2026.10.30 14:30 Benefícios Trabalhistas (Trimestral)
hidden=1
descr=Benefícios Trabalhistas (Trimestral)
color=16119285
selectable=0
date1=1793370600
</object>

<object>
type=109
name=2026.10.30 14:30 Salário Mínimo em Empregos (Trimestral)
hidden=1
descr=Salário Mínimo em Empregos (Trimestral)
color=16119285
selectable=0
date1=1793370600
</object>

<object>
type=109
name=2026.10.30 15:45 Barômetro de Negócios de Chicago
hidden=1
descr=Barômetro de Negócios de Chicago
color=16119285
selectable=0
date1=1793375100
</object>

<object>
type=109
name=2026.10.30 19:00 Contagem de Sondas Baker Hughes
hidden=1
descr=Contagem de Sondas Baker Hughes
color=16119285
selectable=0
date1=1793386800
</object>

<object>
type=109
name=2026.10.30 19:00 Contagem Total de Sondas dos EUA por Baker Hug
hidden=1
descr=Contagem Total de Sondas dos EUA por Baker Hughes
color=16119285
selectable=0
date1=1793386800
</object>

<object>
type=109
name=2026.10.30 21:30 CHF -  Posições Líquidas de Especuladores no R
hidden=1
descr=CHF -  Posições Líquidas de Especuladores no Relatório da CFTC
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 Cobre -  Posições Líquidas de Especuladores no
hidden=1
descr=Cobre -  Posições Líquidas de Especuladores no Relatório da CFT
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 Prata -  Posições Líquidas de Especuladores no
hidden=1
descr=Prata -  Posições Líquidas de Especuladores no Relatório da CFT
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 Ouro -  Posições Líquidas de Especuladores no 
hidden=1
descr=Ouro -  Posições Líquidas de Especuladores no Relatório da CFTC
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 Petróleo bruto - Posições Líquidas de Especula
hidden=1
descr=Petróleo bruto - Posições Líquidas de Especuladores no Relatóri
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 S&P 500 - Posições Líquidas de Especuladores n
hidden=1
descr=S&P 500 - Posições Líquidas de Especuladores no Relatório da CF
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 Alumínio - Posições líquidas de especuladores 
hidden=1
descr=Alumínio - Posições líquidas de especuladores no relatório da C
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 Milho - Posições líquidas de especuladores no 
hidden=1
descr=Milho - Posições líquidas de especuladores no relatório da CFTC
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 Gás Natural - Posições líquidas de especulador
hidden=1
descr=Gás Natural - Posições líquidas de especuladores no relatório d
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 Soja - Posições líquidas de especuladores no r
hidden=1
descr=Soja - Posições líquidas de especuladores no relatório da CFTC
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 Trigo - Posições líquidas de especuladores no 
hidden=1
descr=Trigo - Posições líquidas de especuladores no relatório da CFTC
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=109
name=2026.10.30 21:30 Nasdaq 100 - Posições líquidas de especuladore
hidden=1
descr=Nasdaq 100 - Posições líquidas de especuladores no relatório da
color=16119285
selectable=0
date1=1793395800
</object>

<object>
type=31
name=autotrade #10842838417 buy 0.01 XAUUSD at 3995.39, XAUUSD
hidden=1
descr=XAU_AI_PRO_DEMO
color=11296515
selectable=0
date1=1792981987
value1=3995.390000
</object>

<object>
type=31
name=autotrade #10842838824 buy 0.01 XAUUSD at 3995.72, XAUUSD
hidden=1
descr=XAU_AI_PRO_DEMO
color=11296515
selectable=0
date1=1792981989
value1=3995.720000
</object>

<object>
type=32
name=autotrade #10842850275 sell 0.01 XAUUSD at 3991.93, SL, profit 
hidden=1
descr=[sl 3991.93]
color=1918177
selectable=0
date1=1792982070
value1=3991.930000
</object>

<object>
type=32
name=autotrade #10842854177 sell 0.01 XAUUSD at 3990.63, SL, profit 
hidden=1
descr=[sl 3990.63]
color=1918177
selectable=0
date1=1792982091
value1=3990.630000
</object>

<object>
type=32
name=autotrade #10843217915 sell 0.01 XAUUSD at 3982.46, XAUUSD
hidden=1
descr=XAU_AI_PRO_DEMO
color=1918177
selectable=0
date1=1792983950
value1=3982.460000
</object>

<object>
type=31
name=autotrade #10843239729 buy 0.01 XAUUSD at 3979.66, TP, profit 2
hidden=1
descr=[tp 3979.66]
color=11296515
selectable=0
date1=1792984042
value1=3979.660000
</object>

<object>
type=32
name=autotrade #10843259965 sell 0.1 XAUUSD at 3983.25, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792984134
value1=3983.250000
</object>

<object>
type=32
name=autotrade #10843270612 sell 0.1 XAUUSD at 3988.94, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792984158
value1=3988.940000
</object>

<object>
type=32
name=autotrade #10843280300 sell 0.1 XAUUSD at 3991.66, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792984183
value1=3991.660000
</object>

<object>
type=32
name=autotrade #10843284738 sell 0.1 XAUUSD at 3993.35, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792984192
value1=3993.350000
</object>

<object>
type=32
name=autotrade #10843294504 sell 0.1 XAUUSD at 3995.72, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792984211
value1=3995.720000
</object>

<object>
type=32
name=autotrade #10843327947 sell 0.1 XAUUSD at 3996.00, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792984345
value1=3996.000000
</object>

<object>
type=32
name=autotrade #10843349908 sell 0.1 XAUUSD at 3994.38, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792984442
value1=3994.380000
</object>

<object>
type=32
name=autotrade #10843364677 sell 0.1 XAUUSD at 3999.08, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792984508
value1=3999.080000
</object>

<object>
type=32
name=autotrade #10843373319 sell 0.2 XAUUSD at 3999.32, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792984533
value1=3999.320000
</object>

<object>
type=32
name=autotrade #10843391048 sell 1 XAUUSD at 3999.51, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792984594
value1=3999.510000
</object>

<object>
type=31
name=autotrade #10843494075 buy 0.1 XAUUSD at 3990.53, TP, profit 54
hidden=1
descr=[tp 3990.53]
color=11296515
selectable=0
date1=1792985145
value1=3990.530000
</object>

<object>
type=31
name=autotrade #10843504820 buy 0.1 XAUUSD at 3989.82, profit -65.70
hidden=1
color=11296515
selectable=0
date1=1792985182
value1=3989.820000
</object>

<object>
type=31
name=autotrade #10843504889 buy 0.1 XAUUSD at 3989.95, profit -10.10
hidden=1
color=11296515
selectable=0
date1=1792985183
value1=3989.950000
</object>

<object>
type=31
name=autotrade #10843504986 buy 0.1 XAUUSD at 3990.18, profit 14.80,
hidden=1
color=11296515
selectable=0
date1=1792985183
value1=3990.180000
</object>

<object>
type=31
name=autotrade #10843505072 buy 0.1 XAUUSD at 3990.15, profit 32.00,
hidden=1
color=11296515
selectable=0
date1=1792985184
value1=3990.150000
</object>

<object>
type=31
name=autotrade #10843505156 buy 0.1 XAUUSD at 3990.12, profit 56.00,
hidden=1
color=11296515
selectable=0
date1=1792985184
value1=3990.120000
</object>

<object>
type=31
name=autotrade #10843505211 buy 0.1 XAUUSD at 3990.14, profit 42.40,
hidden=1
color=11296515
selectable=0
date1=1792985184
value1=3990.140000
</object>

<object>
type=31
name=autotrade #10843505270 buy 0.1 XAUUSD at 3990.10, profit 89.80,
hidden=1
color=11296515
selectable=0
date1=1792985185
value1=3990.100000
</object>

<object>
type=31
name=autotrade #10843505332 buy 0.2 XAUUSD at 3990.05, profit 185.40
hidden=1
color=11296515
selectable=0
date1=1792985185
value1=3990.050000
</object>

<object>
type=31
name=autotrade #10843505394 buy 1 XAUUSD at 3990.02, profit 949.00, 
hidden=1
color=11296515
selectable=0
date1=1792985185
value1=3990.020000
</object>

<object>
type=32
name=autotrade #10843904098 sell 1 XAUUSD at 3991.70, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792987438
value1=3991.700000
</object>

<object>
type=32
name=autotrade #10843916425 sell 1 XAUUSD at 3993.23, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792987494
value1=3993.230000
</object>

<object>
type=32
name=autotrade #10843932747 sell 0.5 XAUUSD at 3994.80, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1792987554
value1=3994.800000
</object>

<object>
type=31
name=autotrade #10843949600 buy 0.5 XAUUSD at 3992.76, TP, profit 10
hidden=1
descr=[tp 3992.76]
color=11296515
selectable=0
date1=1792987644
value1=3992.760000
</object>

<object>
type=31
name=autotrade #10843987901 buy 1 XAUUSD at 3991.16, TP, profit 54.0
hidden=1
descr=[tp 3991.16]
color=11296515
selectable=0
date1=1792987876
value1=3991.160000
</object>

<object>
type=31
name=autotrade #10843987907 buy 1 XAUUSD at 3991.16, TP, profit 207.
hidden=1
descr=[tp 3991.16]
color=11296515
selectable=0
date1=1792987876
value1=3991.160000
</object>

<object>
type=32
name=autotrade #10846464140 sell 0.5 XAUUSD at 4012.43, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793001407
value1=4012.430000
</object>

<object>
type=31
name=autotrade #10854133343 buy 0.5 XAUUSD at 4002.16, TP, profit 51
hidden=1
descr=[tp 4002.16]
color=11296515
selectable=0
date1=1793028851
value1=4002.160000
</object>

<object>
type=32
name=autotrade #10863420565 sell 0.5 XAUUSD at 4009.05, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793076739
value1=4009.050000
</object>

<object>
type=31
name=autotrade #10863650437 buy 0.5 XAUUSD at 4007.45, profit 80.00,
hidden=1
color=11296515
selectable=0
date1=1793078439
value1=4007.450000
</object>

<object>
type=32
name=autotrade #10890041677 sell 0.5 XAUUSD at 4039.74, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793215143
value1=4039.740000
</object>

<object>
type=32
name=autotrade #10890057353 sell 0.5 XAUUSD at 4040.27, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793215199
value1=4040.270000
</object>

<object>
type=31
name=autotrade #10890108532 buy 0.5 XAUUSD at 4039.65, profit 4.50, 
hidden=1
color=11296515
selectable=0
date1=1793215458
value1=4039.650000
</object>

<object>
type=31
name=autotrade #10890108703 buy 0.5 XAUUSD at 4039.64, profit 31.50,
hidden=1
color=11296515
selectable=0
date1=1793215459
value1=4039.640000
</object>

<object>
type=32
name=autotrade #10912391595 sell 0.1 XAUUSD at 4008.49, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793304969
value1=4008.490000
</object>

<object>
type=32
name=autotrade #10912398009 sell 0.1 XAUUSD at 4008.59, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793304999
value1=4008.590000
</object>

<object>
type=32
name=autotrade #10912407722 sell 0.1 XAUUSD at 4009.71, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793305046
value1=4009.710000
</object>

<object>
type=31
name=autotrade #10912419835 buy 0.1 XAUUSD at 4008.40, TP, profit 13
hidden=1
descr=[tp 4008.40]
color=11296515
selectable=0
date1=1793305122
value1=4008.400000
</object>

<object>
type=31
name=autotrade #10912440464 buy 0.1 XAUUSD at 4008.07, TP, profit 5.
hidden=1
descr=[tp 4008.07]
color=11296515
selectable=0
date1=1793305249
value1=4008.070000
</object>

<object>
type=31
name=autotrade #10912442527 buy 0.1 XAUUSD at 4008.38, profit 1.10, 
hidden=1
color=11296515
selectable=0
date1=1793305257
value1=4008.380000
</object>

<object>
type=32
name=autotrade #10912454930 sell 0.02 XAUUSD at 4007.91, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793305325
value1=4007.910000
</object>

<object>
type=31
name=autotrade #10912500509 buy 0.02 XAUUSD at 4007.00, profit 1.82,
hidden=1
color=11296515
selectable=0
date1=1793305566
value1=4007.000000
</object>

<object>
type=32
name=autotrade #10944031302 sell 0.2 XAUUSD at 3900.67, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793628477
value1=3900.670000
</object>

<object>
type=32
name=autotrade #10944069970 sell 0.2 XAUUSD at 3902.67, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793628626
value1=3902.670000
</object>

<object>
type=31
name=autotrade #10944074578 buy 0.2 XAUUSD at 3901.66, TP, profit 20
hidden=1
descr=[tp 3901.66]
color=11296515
selectable=0
date1=1793628640
value1=3901.660000
</object>

<object>
type=32
name=autotrade #10944083978 sell 0.2 XAUUSD at 3902.83, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793628668
value1=3902.830000
</object>

<object>
type=32
name=autotrade #10944098781 sell 0.2 XAUUSD at 3905.92, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793628716
value1=3905.920000
</object>

<object>
type=32
name=autotrade #10944126950 sell 0.2 XAUUSD at 3905.90, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793628786
value1=3905.900000
</object>

<object>
type=31
name=autotrade #10944165610 buy 0.2 XAUUSD at 3904.66, TP, profit 25
hidden=1
descr=[tp 3904.66]
color=11296515
selectable=0
date1=1793628916
value1=3904.660000
</object>

<object>
type=31
name=autotrade #10944406763 buy 0.2 XAUUSD at 3902.28, TP, profit 11
hidden=1
descr=[tp 3902.28]
color=11296515
selectable=0
date1=1793629838
value1=3902.280000
</object>

<object>
type=31
name=autotrade #10944444083 buy 0.2 XAUUSD at 3900.47, profit 108.60
hidden=1
color=11296515
selectable=0
date1=1793629940
value1=3900.470000
</object>

<object>
type=31
name=autotrade #10944444297 buy 0.2 XAUUSD at 3900.52, profit 3.00, 
hidden=1
color=11296515
selectable=0
date1=1793629941
value1=3900.520000
</object>

<object>
type=31
name=autotrade #10945102359 buy 0.1 XAUUSD at 3901.11, XAUUSD
hidden=1
color=11296515
selectable=0
date1=1793632132
value1=3901.110000
</object>

<object>
type=32
name=autotrade #10945332281 sell 0.1 XAUUSD at 3902.12, TP, profit 1
hidden=1
descr=[tp 3902.12]
color=1918177
selectable=0
date1=1793632842
value1=3902.120000
</object>

<object>
type=32
name=autotrade #10956398069 sell 0.1 XAUUSD at 3940.66, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793683170
value1=3940.660000
</object>

<object>
type=31
name=autotrade #10956419583 buy 0.1 XAUUSD at 3937.98, TP, profit 26
hidden=1
descr=[tp 3937.98]
color=11296515
selectable=0
date1=1793683298
value1=3937.980000
</object>

<object>
type=32
name=autotrade #10956883729 sell 0.01 XAUUSD at 3926.89, XAUUSD
hidden=1
descr=XAU_AI_PRO_DEMO
color=1918177
selectable=0
date1=1793685468
value1=3926.890000
</object>

<object>
type=31
name=autotrade #10956894656 buy 0.01 XAUUSD at 3926.57, profit 0.32,
hidden=1
color=11296515
selectable=0
date1=1793685543
value1=3926.570000
</object>

<object>
type=32
name=autotrade #11000560117 sell 0.1 XAUUSD at 4130.83, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793852137
value1=4130.830000
</object>

<object>
type=31
name=autotrade #11000565002 buy 0.1 XAUUSD at 4130.02, profit 8.10, 
hidden=1
color=11296515
selectable=0
date1=1793852166
value1=4130.020000
</object>

<object>
type=32
name=autotrade #11000569771 sell 0.1 XAUUSD at 4127.66, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793852188
value1=4127.660000
</object>

<object>
type=31
name=autotrade #11000575896 buy 0.1 XAUUSD at 4129.74, XAUUSD
hidden=1
color=11296515
selectable=0
date1=1793852218
value1=4129.740000
</object>

<object>
type=32
name=autotrade #11000584529 sell 0.1 XAUUSD at 4131.06, TP, profit 1
hidden=1
descr=[tp 4131.06]
color=1918177
selectable=0
date1=1793852272
value1=4131.060000
</object>

<object>
type=32
name=autotrade #11000592276 sell 0.1 XAUUSD at 4131.83, XAUUSD
hidden=1
color=1918177
selectable=0
date1=1793852303
value1=4131.830000
</object>

<object>
type=31
name=autotrade #11000596296 buy 0.1 XAUUSD at 4129.87, profit 19.60,
hidden=1
color=11296515
selectable=0
date1=1793852322
value1=4129.870000
</object>

<object>
type=31
name=autotrade #11000601824 buy 0.1 XAUUSD at 4127.32, TP, profit 3.
hidden=1
descr=[tp 4127.32]
color=11296515
selectable=0
date1=1793852351
value1=4127.320000
</object>

<object>
type=2
name=autotrade #10842838417 -> #10842854177, SL, profit -4.76, XAUUS
hidden=1
descr=3995.39 -> 3990.63
color=11296515
style=2
selectable=0
ray1=0
ray2=0
date1=1792981987
date2=1792982091
value1=3995.390000
value2=3990.630000
</object>

<object>
type=2
name=autotrade #10842838824 -> #10842850275, SL, profit -3.79, XAUUS
hidden=1
descr=3995.72 -> 3991.93
color=11296515
style=2
selectable=0
ray1=0
ray2=0
date1=1792981989
date2=1792982070
value1=3995.720000
value2=3991.930000
</object>

<object>
type=2
name=autotrade #10843217915 -> #10843239729, TP, profit 2.80, XAUUSD
hidden=1
descr=3982.46 -> 3979.66
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792983950
date2=1792984042
value1=3982.460000
value2=3979.660000
</object>

<object>
type=2
name=autotrade #10843259965 -> #10843504820, profit -65.70, XAUUSD
hidden=1
descr=3983.25 -> 3989.82
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792984134
date2=1792985182
value1=3983.250000
value2=3989.820000
</object>

<object>
type=2
name=autotrade #10843270612 -> #10843504889, profit -10.10, XAUUSD
hidden=1
descr=3988.94 -> 3989.95
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792984158
date2=1792985183
value1=3988.940000
value2=3989.950000
</object>

<object>
type=2
name=autotrade #10843280300 -> #10843504986, profit 14.80, XAUUSD
hidden=1
descr=3991.66 -> 3990.18
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792984183
date2=1792985183
value1=3991.660000
value2=3990.180000
</object>

<object>
type=2
name=autotrade #10843284738 -> #10843505072, profit 32.00, XAUUSD
hidden=1
descr=3993.35 -> 3990.15
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792984192
date2=1792985184
value1=3993.350000
value2=3990.150000
</object>

<object>
type=2
name=autotrade #10843294504 -> #10843505156, profit 56.00, XAUUSD
hidden=1
descr=3995.72 -> 3990.12
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792984211
date2=1792985184
value1=3995.720000
value2=3990.120000
</object>

<object>
type=2
name=autotrade #10843327947 -> #10843494075, TP, profit 54.70, XAUUS
hidden=1
descr=3996.00 -> 3990.53
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792984345
date2=1792985145
value1=3996.000000
value2=3990.530000
</object>

<object>
type=2
name=autotrade #10843349908 -> #10843505211, profit 42.40, XAUUSD
hidden=1
descr=3994.38 -> 3990.14
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792984442
date2=1792985184
value1=3994.380000
value2=3990.140000
</object>

<object>
type=2
name=autotrade #10843364677 -> #10843505270, profit 89.80, XAUUSD
hidden=1
descr=3999.08 -> 3990.10
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792984508
date2=1792985185
value1=3999.080000
value2=3990.100000
</object>

<object>
type=2
name=autotrade #10843373319 -> #10843505332, profit 185.40, XAUUSD
hidden=1
descr=3999.32 -> 3990.05
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792984533
date2=1792985185
value1=3999.320000
value2=3990.050000
</object>

<object>
type=2
name=autotrade #10843391048 -> #10843505394, profit 949.00, XAUUSD
hidden=1
descr=3999.51 -> 3990.02
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792984594
date2=1792985185
value1=3999.510000
value2=3990.020000
</object>

<object>
type=2
name=autotrade #10843904098 -> #10843987901, TP, profit 54.00, XAUUS
hidden=1
descr=3991.70 -> 3991.16
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792987438
date2=1792987876
value1=3991.700000
value2=3991.160000
</object>

<object>
type=2
name=autotrade #10843916425 -> #10843987907, TP, profit 207.00, XAUU
hidden=1
descr=3993.23 -> 3991.16
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792987494
date2=1792987876
value1=3993.230000
value2=3991.160000
</object>

<object>
type=2
name=autotrade #10843932747 -> #10843949600, TP, profit 102.00, XAUU
hidden=1
descr=3994.80 -> 3992.76
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1792987554
date2=1792987644
value1=3994.800000
value2=3992.760000
</object>

<object>
type=2
name=autotrade #10846464140 -> #10854133343, TP, profit 513.50, XAUU
hidden=1
descr=4012.43 -> 4002.16
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793001407
date2=1793028851
value1=4012.430000
value2=4002.160000
</object>

<object>
type=2
name=autotrade #10863420565 -> #10863650437, profit 80.00, XAUUSD
hidden=1
descr=4009.05 -> 4007.45
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793076739
date2=1793078439
value1=4009.050000
value2=4007.450000
</object>

<object>
type=2
name=autotrade #10890041677 -> #10890108532, profit 4.50, XAUUSD
hidden=1
descr=4039.74 -> 4039.65
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793215143
date2=1793215458
value1=4039.740000
value2=4039.650000
</object>

<object>
type=2
name=autotrade #10890057353 -> #10890108703, profit 31.50, XAUUSD
hidden=1
descr=4040.27 -> 4039.64
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793215199
date2=1793215459
value1=4040.270000
value2=4039.640000
</object>

<object>
type=2
name=autotrade #10912391595 -> #10912442527, profit 1.10, XAUUSD
hidden=1
descr=4008.49 -> 4008.38
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793304969
date2=1793305257
value1=4008.490000
value2=4008.380000
</object>

<object>
type=2
name=autotrade #10912398009 -> #10912440464, TP, profit 5.20, XAUUSD
hidden=1
descr=4008.59 -> 4008.07
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793304999
date2=1793305249
value1=4008.590000
value2=4008.070000
</object>

<object>
type=2
name=autotrade #10912407722 -> #10912419835, TP, profit 13.10, XAUUS
hidden=1
descr=4009.71 -> 4008.40
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793305046
date2=1793305122
value1=4009.710000
value2=4008.400000
</object>

<object>
type=2
name=autotrade #10912454930 -> #10912500509, profit 1.82, XAUUSD
hidden=1
descr=4007.91 -> 4007.00
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793305325
date2=1793305566
value1=4007.910000
value2=4007.000000
</object>

<object>
type=2
name=autotrade #10944031302 -> #10944444297, profit 3.00, XAUUSD
hidden=1
descr=3900.67 -> 3900.52
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793628477
date2=1793629941
value1=3900.670000
value2=3900.520000
</object>

<object>
type=2
name=autotrade #10944069970 -> #10944074578, TP, profit 20.20, XAUUS
hidden=1
descr=3902.67 -> 3901.66
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793628626
date2=1793628640
value1=3902.670000
value2=3901.660000
</object>

<object>
type=2
name=autotrade #10944083978 -> #10944406763, TP, profit 11.00, XAUUS
hidden=1
descr=3902.83 -> 3902.28
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793628668
date2=1793629838
value1=3902.830000
value2=3902.280000
</object>

<object>
type=2
name=autotrade #10944098781 -> #10944165610, TP, profit 25.20, XAUUS
hidden=1
descr=3905.92 -> 3904.66
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793628716
date2=1793628916
value1=3905.920000
value2=3904.660000
</object>

<object>
type=2
name=autotrade #10944126950 -> #10944444083, profit 108.60, XAUUSD
hidden=1
descr=3905.90 -> 3900.47
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793628786
date2=1793629940
value1=3905.900000
value2=3900.470000
</object>

<object>
type=2
name=autotrade #10945102359 -> #10945332281, TP, profit 10.10, XAUUS
hidden=1
descr=3901.11 -> 3902.12
color=11296515
style=2
selectable=0
ray1=0
ray2=0
date1=1793632132
date2=1793632842
value1=3901.110000
value2=3902.120000
</object>

<object>
type=2
name=autotrade #10956398069 -> #10956419583, TP, profit 26.80, XAUUS
hidden=1
descr=3940.66 -> 3937.98
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793683170
date2=1793683298
value1=3940.660000
value2=3937.980000
</object>

<object>
type=2
name=autotrade #10956883729 -> #10956894656, profit 0.32, XAUUSD
hidden=1
descr=3926.89 -> 3926.57
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793685468
date2=1793685543
value1=3926.890000
value2=3926.570000
</object>

<object>
type=2
name=autotrade #11000560117 -> #11000565002, profit 8.10, XAUUSD
hidden=1
descr=4130.83 -> 4130.02
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793852137
date2=1793852166
value1=4130.830000
value2=4130.020000
</object>

<object>
type=2
name=autotrade #11000569771 -> #11000601824, TP, profit 3.40, XAUUSD
hidden=1
descr=4127.66 -> 4127.32
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793852188
date2=1793852351
value1=4127.660000
value2=4127.320000
</object>

<object>
type=2
name=autotrade #11000575896 -> #11000584529, TP, profit 13.20, XAUUS
hidden=1
descr=4129.74 -> 4131.06
color=11296515
style=2
selectable=0
ray1=0
ray2=0
date1=1793852218
date2=1793852272
value1=4129.740000
value2=4131.060000
</object>

<object>
type=2
name=autotrade #11000592276 -> #11000596296, profit 19.60, XAUUSD
hidden=1
descr=4131.83 -> 4129.87
color=1918177
style=2
selectable=0
ray1=0
ray2=0
date1=1793852303
date2=1793852322
value1=4131.830000
value2=4129.870000
</object>

</window>
</chart>