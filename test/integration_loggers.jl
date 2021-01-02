serverUrl = "http://localhost:5341/"
logger = SeqLogger(serverUrl, ; App="Trialrun")
Logging.global_logger(logger)
@info "Test"
@info "Test invalid string\n, \r, \\ \""
