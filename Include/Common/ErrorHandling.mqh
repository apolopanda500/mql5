//+------------------------------------------------------------------+
//| ErrorHandling.mqh                                                |
//|                                                                  |
//| A value-or-error type for MQL5 - no exceptions. A function       |
//| returns one object that either holds a value or an Error, so the |
//| caller is forced to ask which. Wraps GetLastError/ResetLastError |
//| and maps codes to readable names (see MqlError.mqh).             |
//|                                                                  |
//| When to use which:                                               |
//|   ResultValue<T> - value types (numbers, structs).               |
//|   Result<T>      - objects held by pointer (classes).            |
//|                                                                  |
//| Callbacks (Then / Match / MapError) take top-level or static     |
//| functions: MQL5 has no closures, so a callback sees only the     |
//| passed value/error, not the caller's local context.              |
//|                                                                  |
//| Note: MqlError.mqh declares the MQL_ERROR enum with generic      |
//| member names (SUCCESS, INVALID_PARAMETER, ...). Watch for name   |
//| collisions in consuming code.                                    |
//+------------------------------------------------------------------+

#include <MqlError.mqh>

#define TRY(result)        \
   if ((result).IsError()) \
   {                       \
      return result;       \
   }

#define PRINT_ON_ERROR(result)                    \
   if ((result).IsError())                        \
   {                                              \
      Print((result).CurrentError().description); \
      return;                                     \
   }

#define RETURN_ON_ERROR(result, returnValue)      \
   if ((result).IsError())                        \
   {                                              \
      Print((result).CurrentError().description); \
      return returnValue;                         \
   }

#define RETURN_SAME_ON_ERROR(result, print)          \
   if ((result).IsError())                           \
   {                                                 \
      if (print)                                     \
      {                                              \
         Print((result).CurrentError().description); \
      }                                              \
      return result;                                 \
   }

#define RESULT_ON_ERROR(result, returnType)             \
   if ((result).IsError())                              \
   {                                                    \
      return returnType::Fail((result).CurrentError()); \
   }

struct Error
{
public:
   int code;
   string description;

   Error() : code(0), description("") {}
   Error(const int errorCode) : code(errorCode), description(EnumToString((MQL_ERROR)code)) {}
   Error(const string &inputDescription) : code(0), description(inputDescription) {}
   Error(const int inputCode, const string &inputDescription) : code(inputCode), description(inputDescription) {}

   static Error Empty()
   {
      Error error;
      return error;
   }

   static Error FromErrorCode(const int errorCode)
   {
      Error error(errorCode);
      return error;
   }

   static Error FromDescription(const string &description)
   {
      Error error(description);
      return error;
   }

   static Error Create(const int code, const string &description)
   {
      Error error(code, description);
      return error;
   }
};

class MQLError
{
public:
   static Error Last()
   {
      return Error(GetLastError());
   }

   static void Reset()
   {
      ResetLastError();
   }

   static void Throw(const ushort userCode)
   {
      SetUserError(userCode);
   }
};

template <typename T>
struct ResultValue
{
private:
   bool _hasError;
   T _value;
   Error _error;

   ResultValue(const T &value) : _value(value), _hasError(false) {}
   ResultValue(const Error &error) : _error(error), _hasError(true) {}

   typedef void (*OnOkFunction)(const T &value);
   typedef void (*OnErrorFunction)(const Error &error);
   typedef ResultValue<T> (*ThenFunction)(const T &value);
   typedef Error (*MapErrorFunction)(const Error &error);

public:
   static ResultValue<T> Ok(const T &value)
   {
      MQLError::Reset();
      return ResultValue<T>(value);
   }

   static ResultValue<T> Fail()
   {
      Error lastError = MQLError::Last();
      MQLError::Reset();
      return ResultValue<T>(lastError);
   }

   static ResultValue<T> Fail(const Error &error)
   {
      MQLError::Reset();
      return ResultValue<T>(error);
   }

   static ResultValue<T> Fail(const string &message)
   {
      Error lastError = MQLError::Last();
      MQLError::Reset();
      return ResultValue<T>(Error::Create(lastError.code, message));
   }

   T Value() const
   {
      return _value;
   }

   T ValueOr(const T &fallback) const
   {
      return _hasError ? fallback : _value;
   }

   Error CurrentError() const
   {
      return _error;
   }

   bool IsError() const
   {
      return _hasError;
   }

   ResultValue<T> Then(ThenFunction function)
   {
      if (_hasError)
      {
         return ResultValue<T>::Fail(_error);
      }
      return function(_value);
   }

   void Match(OnOkFunction onOk, OnErrorFunction onError)
   {
      if (_hasError)
      {
         onError(_error);
      }
      else
      {
         onOk(_value);
      }
   }

   ResultValue<T> MapError(MapErrorFunction function)
   {
      if (!_hasError)
      {
         return this;
      }
      return ResultValue<T>::Fail(function(_error));
   }
};

template <typename T>
class Result
{
private:
   bool _hasError;
   T *_value;
   Error _error;

   Result(T *value) : _value(value), _hasError(false) {}
   Result(const Error &error) : _value(NULL), _error(error), _hasError(true) {}

   typedef void (*OnOkFunction)(T *value);
   typedef void (*OnErrorFunction)(const Error &error);
   typedef Result<T> (*ThenFunction)(T *value);
   typedef Error (*MapErrorFunction)(const Error &error);

public:
   static Result<T> Ok(T *value)
   {
      MQLError::Reset();
      return Result<T>(value);
   }

   static Result<T> Fail()
   {
      Error lastError = MQLError::Last();
      MQLError::Reset();
      return Result<T>(lastError);
   }

   static Result<T> Fail(const Error &error)
   {
      MQLError::Reset();
      return Result<T>(error);
   }

   static Result<T> Fail(const string &message)
   {
      Error lastError = MQLError::Last();
      MQLError::Reset();
      return Result<T>(Error::Create(lastError.code, message));
   }

   T *Value() const
   {
      return _value;
   }

   T *ValueOr(T *fallback) const
   {
      return _hasError ? fallback : _value;
   }

   Error CurrentError() const
   {
      return _error;
   }

   bool IsError() const
   {
      return _hasError;
   }

   Result<T> Then(ThenFunction function)
   {
      if (_hasError)
      {
         return Result<T>::Fail(_error);
      }
      return function(_value);
   }

   void Match(OnOkFunction onOk, OnErrorFunction onError)
   {
      if (_hasError)
      {
         onError(_error);
      }
      else
      {
         onOk(_value);
      }
   }

   Result<T> MapError(MapErrorFunction function)
   {
      if (!_hasError)
      {
         return this;
      }
      return Result<T>::Fail(function(_error));
   }
};