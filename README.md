# shell-logging-library

This repository contains a Bash script logging library that enhances the logging
capabilities with configurable log levels and timestamp precision. It's designed
to be easily integrated into other shell scripts to provide better debugging,
information tracking, warning issuance, and error reporting with color-coded
output based on severity.

<p align="center"><img src="docs/screencast/demo.jpg?raw=true"/></p>

## Features

- [x] **Configurable Log Levels**: Debug, Info, Warn, and Error.
- [x] **Timestamps**: Supports milliseconds precision if available.
- [x] **Color-Coded Output**: Different colors based on log level.
- [x] **Easy Integration**: Source the library in other scripts to start using the enhanced logging.
- [ ] **Error Output Redirection**: Redirect error logs to separate files or syslog.
- [ ] **Function Execution Time Tracking**: Automatically log the execution time of functions to help in performance monitoring.

## Installation

Clone this repository:

```bash
git clone https://github.com/DehanLUO/shell-logging-library.git
```

## Usage

Set the log level by defining LIBLOG_LOG_LEVEL before sourcing the library:

```bash
export LIBLOG_LOG_LEVEL=1  # 0:Debug, 1:Info, 2:Warn, 3:Error.
source liblog.sh
```
Use the logging functions in your script:

```bash
liblog::debug "This is a debug log entry."
liblog::info "This is an info log entry."
liblog::warn "This is a warning log entry."
liblog::err "This is an error log entry."
```

## Contributing

Contributions are welcome!
Feel free to fork the repository and submit pull requests.

## License

This project is licensed under the [MIT License](./LICENSE).