var documenterSearchIndex = {"docs":
[{"location":"","page":"Home","title":"Home","text":"CurrentModule = SeqLoggers","category":"page"},{"location":"#SeqLoggers","page":"Home","title":"SeqLoggers","text":"","category":"section"},{"location":"","page":"Home","title":"Home","text":"","category":"page"},{"location":"","page":"Home","title":"Home","text":"Modules = [SeqLoggers]","category":"page"},{"location":"#SeqLoggers.SeqLogger","page":"Home","title":"SeqLoggers.SeqLogger","text":"SeqLogger(serverUrl=\"http://localhost:5341\", postType=Background();\n               minLevel=Logging.Info, apiKey=\"\", kwargs...)\n\nLogger that sends log events to a Seq logging server.\n\nNotes\n\nThe kwargs correspond to additional log event properties that can be added \"globally\" for a SeqLogger instance. e.g. App = \"DJSON\", Env = \"Test\" # Dev, Prod, Test, UAT, HistoryId = \"xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx\"\n\nAdditional log events can also be added separately for each idividual log event @info \"Event\" logEventProperty=\"logEventValue\"\n\n\n\n\n\n","category":"type"},{"location":"#Logging.with_logger-Tuple{Function,LoggingExtras.TeeLogger}","page":"Home","title":"Logging.with_logger","text":"Logging.with_logger(@nospecialize(f::Function), demuxLogger::TeeLogger)\n\nExtends the method Logging.with_logger to work for a LoggingExtras.TeeLogger containing a SeqLogger.\n\n\n\n\n\n","category":"method"},{"location":"#Logging.with_logger-Tuple{Function,SeqLogger}","page":"Home","title":"Logging.with_logger","text":"Logging.with_logger(@nospecialize(f::Function), logger::SeqLogger)\n\nExtends the method Logging.with_logger to work for a SeqLogger.\n\n\n\n\n\n","category":"method"},{"location":"#SeqLoggers.flush_current_logger-Tuple{}","page":"Home","title":"SeqLoggers.flush_current_logger","text":"flush_current_logger()\n\nPost the events in the logger batch event for the logger for the current task, or the global logger if none is attached to the task.\n\nNote\n\nIn the main moduel of Atom, the current_logger is Atom.Progress.JunoProgressLogger(). Therefore, if you set SeqLogger as a Logging.global_logger in in Atom use flush_global_logger.\n\n\n\n\n\n","category":"method"},{"location":"#SeqLoggers.flush_events-Tuple{LoggingExtras.TeeLogger}","page":"Home","title":"SeqLoggers.flush_events","text":"flush_events(teeLogger::LoggingExtras.TeeLogger)\n\nExtend flush_events to a work for a LoggingExtras.TeeLogger containing a SeqLogger.\n\n\n\n\n\n","category":"method"},{"location":"#SeqLoggers.flush_global_logger-Tuple{}","page":"Home","title":"SeqLoggers.flush_global_logger","text":"flush_global_logger()\n\nPost the events in the logger batch event for the global logger.\n\nNote\n\nIf the logger is run with Logging.with_logger, this is considered a current logger Logging.current_logger and  flush_current_logger. needs to be used.\n\n\n\n\n\n","category":"method"}]
}