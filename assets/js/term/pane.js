import React from "react"
import ReactDOM from 'react-dom';
import Terminal from "./term"

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
        screenKeys: true,
        cursorBlink: false,
        rows: this.props.rows,
        cols: this.props.cols,
        useFocus: false,
        tmate_pane: this,
      })

      term.on('data', data => {
        this.props.session.send_pty_keys(this.props.id, data)
      })

      term.debug = true
      term.on('error', msg => console.log(`error: ${msg}`))

      term.open(ReactDOM.findDOMNode(this))

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
  }

  componentWillUnmount() {
    this.props.session.on_umount_pane(this.props.id)
    this.term.close()
    this.term = undefined
  }

  on_bootstrap_grid(...args) {
    bootstrap_grid(this.term, ...args)
  }

  on_pty_data(data) {
    this.term.write(data)
  }
}

const bootstrap_mode = (term, mode) => {
  if (mode & MODE_CURSOR)
    term.applicationCursor = true
  if (mode & MODE_WRAP)
    term.wraparoundMode = true
  if (mode & ALL_MOUSE_MODES) {
    term.x10Mouse = false
    term.vt200Mouse = true
    term.normalMouse = false
    term.mouseEvents = true
    term.element.style.cursor = 'default'
  }
  if (mode & MODE_FOCUSON)
    term.sendFocus = true
  if (mode & MODE_MOUSE_UTF8)
    term.utfMouse = true
  if (mode & MODE_MOUSE_SGR)
    term.sgrMouse = true
  if (!(mode & MODE_CURSOR))
    term.cursorHidden = true
}

const bootstrap_grid = (term, cursor_pos, mode, grid_data) => {
  const [cx, cy] = cursor_pos

  const term_attr = packed_attrs => {
    let fg    = packed_attrs & 0xFF
    let bg    = (packed_attrs >> 8)  & 0xFF
    let attr  = (packed_attrs >> 16) & 0xFF
    let flags = (packed_attrs >> 24) & 0xFF

    if (fg == 8)
      fg = (term.defAttr >> 9) & 0x1ff;
    if (bg == 8)
      bg = term.defAttr & 0x1ff;

    let new_flags = 0
    if (attr & GRID_ATTR_BRIGHT)     new_flags |= 1  /* bold */
    if (attr & GRID_ATTR_UNDERSCORE) new_flags |= 2  /* underline */
    if (attr & GRID_ATTR_BLINK)      new_flags |= 4  /* blink */
    if (attr & GRID_ATTR_REVERSE)    new_flags |= 8  /* inverse */
    if (attr & GRID_ATTR_HIDDEN)     new_flags |= 16 /* invisible */

    let new_attr = (new_flags << 18) | (fg << 9) | bg

    return new_attr
  }

  term.lines = []
  const cols = term.cols

  for (const line_data of grid_data) {
    const [chars, attrs] = line_data

    let line = []
    for (let i = 0; i < cols; i++) {
      // careful with multi-cells utf8 chars
      let c = chars[i]
      if (c === undefined)
        line[i] = [term.defAttr, ' ']
      else
        line[i] = [term_attr(attrs[i]), c]
    }
    term.lines.push(line)
  }

  term.ydisp = grid_data.length - term.rows
  term.ybase = term.ydisp

  term.x = cx
  term.y = cy

  bootstrap_mode(term, mode)

  term.refresh(0, term.rows - 1);
}
