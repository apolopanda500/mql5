//+------------------------------------------------------------------+
//|                                           NotificationCenter.mqh |
//|                                  Notification Center             |
//|                                            XAU_AI_PRO v1.2.0       |
//+------------------------------------------------------------------+

#ifndef NOTIFICATION_CENTER_MQH
#define NOTIFICATION_CENTER_MQH

enum NotifyChannel { NOTIFY_TELEGRAM, NOTIFY_DISCORD, NOTIFY_EMAIL, NOTIFY_PUSH };
enum NotifyPriority { NOTIFY_LOW, NOTIFY_NORMAL, NOTIFY_HIGH, NOTIFY_CRITICAL };

class CNotificationCenter
{
private:
   static bool m_initialized;
   static string m_telegram_token;
   static string m_telegram_chat_id;
   static string m_discord_webhook;
   static string m_email_smtp;
   static bool   m_telegram_enabled;
   static bool   m_discord_enabled;
   static bool   m_email_enabled;
   static bool   m_push_enabled;
   static int    m_sent_count;
   static int    m_failed_count;
public:
   static void Init();
   static void ConfigureTelegram(const string token, const string chat_id);
   static void ConfigureDiscord(const string webhook);
   static void ConfigureEmail(const string smtp_server);
   static void EnableChannel(NotifyChannel channel);
   static void DisableChannel(NotifyChannel channel);
   static bool Send(const string message, NotifyPriority priority);
   static bool SendTradeOpen(string symbol, double volume, double price, string type);
   static bool SendTradeClose(string symbol, double profit, string comment);
   static bool SendError(string module, string error);
   static bool SendDrawdown(double dd_percent);
   static bool SendDailyReport(double profit, int trades, double win_rate);
   static bool SendSystemAlert(string alert);
   static int GetSentCount();
   static int GetFailedCount();
   static string GetStatus();
   static void LogStatus();
};

bool CNotificationCenter::m_initialized = false;
string CNotificationCenter::m_telegram_token = "";
string CNotificationCenter::m_telegram_chat_id = "";
string CNotificationCenter::m_discord_webhook = "";
string CNotificationCenter::m_email_smtp = "";
bool CNotificationCenter::m_telegram_enabled = false;
bool CNotificationCenter::m_discord_enabled = false;
bool CNotificationCenter::m_email_enabled = false;
bool CNotificationCenter::m_push_enabled = true;
int CNotificationCenter::m_sent_count = 0;
int CNotificationCenter::m_failed_count = 0;

void CNotificationCenter::Init()
{
   if(m_initialized) return;
   m_initialized = true;
   Print("[NOTIFY] NotificationCenter initialized");
}

void CNotificationCenter::ConfigureTelegram(const string token, const string chat_id)
{
   m_telegram_token = token;
   m_telegram_chat_id = chat_id;
   m_telegram_enabled = (token != "" && chat_id != "");
}

void CNotificationCenter::ConfigureDiscord(const string webhook)
{
   m_discord_webhook = webhook;
   m_discord_enabled = (webhook != "");
}

void CNotificationCenter::ConfigureEmail(const string smtp_server)
{
   m_email_smtp = smtp_server;
   m_email_enabled = (smtp_server != "");
}

void CNotificationCenter::EnableChannel(NotifyChannel channel)
{
   switch(channel)
   {
      case NOTIFY_TELEGRAM: m_telegram_enabled = true; break;
      case NOTIFY_DISCORD: m_discord_enabled = true; break;
      case NOTIFY_EMAIL: m_email_enabled = true; break;
      case NOTIFY_PUSH: m_push_enabled = true; break;
   }
}

void CNotificationCenter::DisableChannel(NotifyChannel channel)
{
   switch(channel)
   {
      case NOTIFY_TELEGRAM: m_telegram_enabled = false; break;
      case NOTIFY_DISCORD: m_discord_enabled = false; break;
      case NOTIFY_EMAIL: m_email_enabled = false; break;
      case NOTIFY_PUSH: m_push_enabled = false; break;
   }
}

bool CNotificationCenter::Send(const string message, NotifyPriority priority)
{
   bool sent = false;
   
   // Push notification (always available)
   if(m_push_enabled)
   {
      SendNotification(message);
      sent = true;
   }
   
   // Telegram
   if(m_telegram_enabled)
   {
      // Would need WebRequest to Telegram API
      PrintFormat("[NOTIFY] Telegram: %s", message);
      sent = true;
   }
   
   // Discord
   if(m_discord_enabled)
   {
      // Would need WebRequest to Discord webhook
      PrintFormat("[NOTIFY] Discord: %s", message);
      sent = true;
   }
   
   // Email
   if(m_email_enabled)
   {
      // Would need SendMail
      PrintFormat("[NOTIFY] Email: %s", message);
      sent = true;
   }
   
   if(sent) m_sent_count++; else m_failed_count++;
   return sent;
}

bool CNotificationCenter::SendTradeOpen(string symbol, double volume, double price, string type)
{
   string msg = StringFormat("?? TRADE OPEN | %s %s %.2f lots @ %.5f", type, symbol, volume, price);
   return Send(msg, NOTIFY_NORMAL);
}

bool CNotificationCenter::SendTradeClose(string symbol, double profit, string comment)
{
   string emoji = profit >= 0 ? "?" : "?";
   string msg = StringFormat("%s TRADE CLOSE | %s | P/L: %.2f | %s", emoji, symbol, profit, comment);
   return Send(msg, NOTIFY_NORMAL);
}

bool CNotificationCenter::SendError(string module, string error)
{
   string msg = StringFormat("?? ERROR | %s: %s", module, error);
   return Send(msg, NOTIFY_HIGH);
}

bool CNotificationCenter::SendDrawdown(double dd_percent)
{
   string msg = StringFormat("?? DRAWDOWN | %.2f%%", dd_percent);
   return Send(msg, NOTIFY_HIGH);
}

bool CNotificationCenter::SendDailyReport(double profit, int trades, double win_rate)
{
   string msg = StringFormat("?? DAILY REPORT | Profit: %.2f | Trades: %d | WinRate: %.1f%%", profit, trades, win_rate);
   return Send(msg, NOTIFY_LOW);
}

bool CNotificationCenter::SendSystemAlert(string alert)
{
   return Send(StringFormat("?? ALERT | %s", alert), NOTIFY_CRITICAL);
}

int CNotificationCenter::GetSentCount() { return m_sent_count; }
int CNotificationCenter::GetFailedCount() { return m_failed_count; }

string CNotificationCenter::GetStatus()
{
   return StringFormat("Sent: %d | Failed: %d | Telegram: %s | Discord: %s | Email: %s | Push: %s",
      m_sent_count, m_failed_count,
      m_telegram_enabled ? "ON" : "OFF",
      m_discord_enabled ? "ON" : "OFF",
      m_email_enabled ? "ON" : "OFF",
      m_push_enabled ? "ON" : "OFF");
}

void CNotificationCenter::LogStatus() { Print("[NOTIFY] " + GetStatus()); }

#endif // NOTIFICATION_CENTER_MQH
