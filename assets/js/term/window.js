import React from "react"
import Pane from "./pane"

export default class Window extends React.Component {
  render() {
    const win_size = this.props.session.state.size

    const panes = this.props.panes.map(pane => {
      const [id, cols, rows, x, y] = pane

      const pane_style = {left: this.props.session.get_row_width(x),
                          top:  this.props.session.get_col_height(y)}
      const active = this.props.active && this.props.active_pane_id === id
      const class_name = active && this.props.panes.length > 1 ?
                           "pane_container active" : "pane_container"

      return <div key={id} className={class_name} style={pane_style}>
               <Pane key={id} window={this} session={this.props.session} id={id}
                     cols={cols} rows={rows} active={active} />
             </div>
    })

    const style = {width: this.props.session.get_row_width(win_size[0]) +
                          this.props.session.terminal_padding_size.width,
                   height: this.props.session.get_col_height(win_size[1]) +
                           this.props.session.terminal_padding_size.height}
    return <div className="window" style={style}>{panes}</div>
  }
}
