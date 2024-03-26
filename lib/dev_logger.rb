# custom color-coded logging
class DevLogger < Logger::Formatter
  PAL = {
    black: "\u001b[30m",
    red: "\u001b[31m",
    green: "\u001b[32m",
    yellow: "\u001b[33m",
    blue: "\u001b[34m",
    magenta: "\u001b[35m",
    cyan: "\u001b[36m",
    white: "\u001b[37m",
    reset: "\u001b[0m"
  }

  SEV = {
    debug: "DBG",
    info: "NFO",
    warn: "WRN",
    error: "ERR",
    fatal: "FTL",
    unknown: "UNK"
  }

  CLR = {
    debug: PAL[:green],
    info: PAL[:white],
    warn: PAL[:yellow],
    error: PAL[:red],
    fatal: PAL[:red]
  }

  def initialize(app_name = "dev")
    @app = app_name
  end

  def call(severity, time, progname, msg)
    sev = severity.to_sym.downcase
    msg = msg&.truncate(500, omission: "...")
    "#{CLR[sev]}[#{@app} #{SEV[sev]}] #{msg}#{PAL[:reset]}\n"
  end
end
