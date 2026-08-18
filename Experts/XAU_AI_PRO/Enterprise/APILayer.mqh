//+------------------------------------------------------------------+
//|                                                      APILayer.mqh |
//|                                  API Layer for External Comms    |
//|                                            XAU_AI_PRO v1.2.0       |
//+------------------------------------------------------------------+

#ifndef API_LAYER_MQH
#define API_LAYER_MQH

enum APIProtocol { API_REST, API_WEBSOCKET, API_FILE, API_NAMEDPIPE };

struct APIRequest
{
   string      url;
   string      method;
   string      headers;
   string      body;
   int         timeout;
   datetime    timestamp;
};

struct APIResponse
{
   int         status_code;
   string      body;
   string      error;
   datetime    timestamp;
};

class CAPILayer
{
private:
   static bool m_initialized;
   static string m_base_url;
   static string m_api_key;
   static int    m_timeout_ms;
   static int    m_request_count;
   static int    m_success_count;
   static int    m_error_count;
   static APIResponse ExecuteRequest(APIRequest &req);
public:
   static void Init();
   static void Configure(const string base_url, const string api_key, int timeout_ms);
   static APIResponse Get(const string endpoint);
   static APIResponse Post(const string endpoint, const string data);
   static APIResponse Put(const string endpoint, const string data);
   static APIResponse Delete(const string endpoint);
   
   // Specific API methods
   static bool SendTradeData(ulong ticket, string symbol, double profit);
   static bool SendTelemetry(string metric, double value);
   static bool SendHeartbeat();
   static string GetServerTime();
   static bool SyncConfig();
   
   static int GetRequestCount();
   static int GetSuccessCount();
   static int GetErrorCount();
   static string GetStatus();
   static void LogStatus();
};

bool CAPILayer::m_initialized = false;
string CAPILayer::m_base_url = "";
string CAPILayer::m_api_key = "";
int CAPILayer::m_timeout_ms = 5000;
int CAPILayer::m_request_count = 0;
int CAPILayer::m_success_count = 0;
int CAPILayer::m_error_count = 0;

void CAPILayer::Init()
{
   if(m_initialized) return;
   m_initialized = true;
   Print("[API] APILayer initialized");
}

void CAPILayer::Configure(const string base_url, const string api_key, int timeout_ms)
{
   m_base_url = base_url;
   m_api_key = api_key;
   m_timeout_ms = timeout_ms;
}

APIResponse CAPILayer::ExecuteRequest(APIRequest &req)
{
   APIResponse resp;
   resp.timestamp = TimeCurrent();
   
   // Simplified - would use WebRequest in real implementation
   resp.status_code = 200;
   resp.body = "{\"status\":\"ok\"}";
   resp.error = "";
   
   m_request_count++;
   m_success_count++;
   
   return resp;
}

APIResponse CAPILayer::Get(const string endpoint)
{
   APIRequest req;
   req.url = m_base_url + endpoint;
   req.method = "GET";
   req.headers = "Authorization: Bearer " + m_api_key;
   req.timeout = m_timeout_ms;
   req.timestamp = TimeCurrent();
   return ExecuteRequest(req);
}

APIResponse CAPILayer::Post(const string endpoint, const string data)
{
   APIRequest req;
   req.url = m_base_url + endpoint;
   req.method = "POST";
   req.headers = "Authorization: Bearer " + m_api_key + "\r\nContent-Type: application/json";
   req.body = data;
   req.timeout = m_timeout_ms;
   req.timestamp = TimeCurrent();
   return ExecuteRequest(req);
}

APIResponse CAPILayer::Put(const string endpoint, const string data) { return Post(endpoint, data); }
APIResponse CAPILayer::Delete(const string endpoint) { return Get(endpoint); }

bool CAPILayer::SendTradeData(ulong ticket, string symbol, double profit)
{
   string data = StringFormat("{\"ticket\":%llu,\"symbol\":\"%s\",\"profit\":%.2f}", ticket, symbol, profit);
   APIResponse resp = Post("/api/trades", data);
   return (resp.status_code == 200);
}

bool CAPILayer::SendTelemetry(string metric, double value)
{
   string data = StringFormat("{\"metric\":\"%s\",\"value\":%.2f}", metric, value);
   APIResponse resp = Post("/api/telemetry", data);
   return (resp.status_code == 200);
}

bool CAPILayer::SendHeartbeat()
{
   APIResponse resp = Get("/api/heartbeat");
   return (resp.status_code == 200);
}

string CAPILayer::GetServerTime()
{
   APIResponse resp = Get("/api/time");
   return resp.body;
}

bool CAPILayer::SyncConfig()
{
   APIResponse resp = Get("/api/config");
   return (resp.status_code == 200);
}

int CAPILayer::GetRequestCount() { return m_request_count; }
int CAPILayer::GetSuccessCount() { return m_success_count; }
int CAPILayer::GetErrorCount() { return m_error_count; }

string CAPILayer::GetStatus()
{
   return StringFormat("Requests: %d | Success: %d | Errors: %d | Base: %s", m_request_count, m_success_count, m_error_count, m_base_url);
}

void CAPILayer::LogStatus() { Print("[API] " + GetStatus()); }

#endif // API_LAYER_MQH
