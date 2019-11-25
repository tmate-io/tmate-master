import React from "react"
import ReactDOM from 'react-dom';
import { Terminal } from 'xterm';
import 'xterm/css/xterm.css';
import { Attributes, FgFlags, BgFlags } from "./xterm_constants.ts";

/* tmux grid attrs */
const GRID_ATTR_BRIGHT     = 0x1
const GRID_ATTR_DIM        = 0x2
const GRID_ATTR_UNDERSCORE = 0x4
const GRID_ATTR_BLINK      = 0x8
const GRID_ATTR_REVERSE    = 0x10
const GRID_ATTR_HIDDEN     = 0x20
const GRID_ATTR_ITALICS    = 0x40
const GRID_ATTR_CHARSET    = 0x80

/* tmux modes */
const MODE_CURSOR         = 0x1
const MODE_INSERT         = 0x2
const MODE_KCURSOR        = 0x4
const MODE_KKEYPAD        = 0x8	 /* set = application, clear = number */
const MODE_WRAP           = 0x10 /* whether lines wrap */
const MODE_MOUSE_STANDARD = 0x20
const MODE_MOUSE_BUTTON   = 0x40
const MODE_MOUSE_ANY      = 0x80
const MODE_MOUSE_UTF8     = 0x100
const MODE_MOUSE_SGR      = 0x200
const MODE_BRACKETPASTE   = 0x400
const MODE_FOCUSON        = 0x800
const ALL_MOUSE_MODES     = (MODE_MOUSE_STANDARD|MODE_MOUSE_BUTTON|MODE_MOUSE_ANY)

export default class Pane extends React.Component {
  componentDidMount() {
    if (this.term === undefined) {
      let term = new Terminal({
        // screenKeys: true,
        cursorBlink: false,
        rows: this.props.rows,
        cols: this.props.cols,
        disableStdin: false, /* set with readonly mode */
        fontFamily: "DejaVu Sans Mono, Liberation Mono, monospace",
        fontSize: 12,
        // lineHeight: 14/12,
        macOptionIsMeta: true,
        LogLevel: 'debug'
        // useFocus: false,
        // tmate_pane: this
      });


      /* TODO onBinary */
      term.onData(data => {
        this.props.session.send_pty_keys(this.props.id, data)
      })

      window.term = term
      // term.debug = true
      // term.on('error', msg => console.log(`error: ${msg}`))

      term.open(ReactDOM.findDOMNode(this))

      const dims = term._core._renderService.dimensions;
      this.props.session.set_char_size(dims.actualCellWidth, dims.actualCellHeight);

      if (this.props.active)
        term.focus()

      this.term = term

      this.props.session.get_pane_event_buffer(this.props.id).set_handler({
        on_pty_data: this.on_pty_data.bind(this),
        on_bootstrap_grid: this.on_bootstrap_grid.bind(this),
      })
    }
  }

  render() {
    return <div className="pane" onFocus={this.on_focus.bind(this)}/>
  }

  on_focus() {
    if (this.props.window.props.active_pane_id !== this.props.id)
      this.props.session.focus_pane(this.props.id)
  }

  componentDidUpdate() {
    this.term.resize(this.props.cols, this.props.rows)

    if (this.props.active)
      this.term.focus()

    this.term._core.cursorHidden = !this.props.active;
    this.term.refresh(this.term.buffer.cursorY, this.term.buffer.cursorY);
  }

  componentWillUnmount() {
    this.props.session.on_umount_pane(this.props.id)
    if (this.term) {
      this.term.dispose()
      this.term = undefined
    }
  }

  on_bootstrap_grid(...args) {
    bootstrap_grid(this.term, ...args)
  }

  on_pty_data(data) {
    this.term.write(data)
  }
}

const bootstrap_grid = (term, cursor_pos, mode, grid_data) => {
  const term_attr = packed_attrs => {
    let fg    = packed_attrs & 0xFF
    let bg    = (packed_attrs >> 8)  & 0xFF
    let attr  = (packed_attrs >> 16) & 0xFF
    let flags = (packed_attrs >> 24) & 0xFF

    if (fg != 8)
      fg |= Attributes.CM_P256
    if (bg != 8)
      bg |= Attributes.CM_P256

    if (attr & GRID_ATTR_BRIGHT)     fg |= FgFlags.BOLD
    if (attr & GRID_ATTR_UNDERSCORE) fg |= FgFlags.UNDERLINE
    if (attr & GRID_ATTR_BLINK)      fg |= FgFlags.BLINK
    if (attr & GRID_ATTR_REVERSE)    fg |= FgFlags.INVERSE
    if (attr & GRID_ATTR_HIDDEN)     fg |= FgFlags.INVISIBLE
    if (attr & GRID_ATTR_DIM)        bg |= BgFlags.DIM
    if (attr & GRID_ATTR_ITALICS)    bg |= BgFlags.ITALIC

    return [fg, bg]
  }

  const [cursor_x, cursor_y] = cursor_pos
  const [cols, rows] = [term.rows, term.cols]
  const buffer = term.buffer._buffer;

  /*
   * This gets us an empty line. We should call
   * getBlankLine(DEFAULT_ATTR_DATA), but we don't have access
   * to the constant.
   */
  buffer.clear();
  buffer.fillViewportRows();
  const emptyLine = buffer.lines.get(0).clone();

  grid_data.forEach((line_data, i) => {
    const [chars, attrs] = line_data

    let line = emptyLine.clone();

    for (let j = 0; j < chars.length; j++) {
      let c = chars.charCodeAt(j)
      const width = 1; /* TODO */
      const [fg, bg] = term_attr(attrs[j])
      line.setCellFromCodePoint(j, c, width, fg, bg)
    }

    buffer.lines.push(line)
  });

  buffer.ydisp = grid_data.length
  buffer.ybase = buffer.ydisp

  buffer.x = cursor_x
  buffer.y = cursor_y

  const core = term._core
  // if (mode & MODE_CURSOR)
    // core.applicationCursor = true
  core.wraparoundMode = !!(mode & MODE_WRAP)
  if (mode & ALL_MOUSE_MODES)
    core._coreMouseService.activeProtocol = "VT200"
  core.sendFocus = !!(mode & MODE_FOCUSON)
  // if (mode & MODE_MOUSE_UTF8)
    // core.utfMouse = true
  // if (mode & MODE_MOUSE_SGR)
    // core.sgrMouse = true
  core.cursorHidden = !(mode & MODE_CURSOR);

  term.refresh(0, term.rows - 1);
}
