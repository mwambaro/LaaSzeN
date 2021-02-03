import React from "react"
import PropTypes from "prop-types"

class SiteLogo extends React.Component {
    render(){
        return(
            <div id={this.props.logo_id} 
                 onClick={this.onClick.bind(this)}
                 onMouseOver={this.onMouseOver.bind(this)}
            >
                <span id={this.props.logo_text_id}> {this.props.logo_text}  </span>   
            </div>
        );
    }

    componentDidMount(){
        this.applyStyleToLogo();
    }
    
    onClick(e){
        if(typeof(this) === 'undefined'){
            console.log("onClick: 'this' object is undefined");
            return;
        }
        e.preventDefault();
        
        let url = this.props.logo_click_url;
        if(url){
            if(url !== ''){
                window.location = url;
            }
        }
    }
    
    /// <brief>
    /// Change cursor to pointer
    /// </brief>
    onMouseOver(e){
        if(typeof(this) === 'undefined'){
            console.log("onMouseOver: 'this' object is undefined");
            return;
        }
        e.preventDefault();
        let logo = document.getElementById(this.props.logo_id);
        if(logo){
            logo.style.cursor = "pointer";
        }
    }

    visualLength(text){
        let width = 0;
        let ruler = document.getElementById(this.props.logo_id);
        if(ruler){
            let css = window.getComputedStyle(ruler);
        }

        return width;
    }

    applyStyleToLogo(){
        let logo_text = document.getElementById(this.props.logo_text_id);
        if(logo_text){
            let visual_width = this.visualLength(logo_text.innerText);
            let logo = document.getElementById(this.props.logo_id);
            if(logo){
                let width = visual_width ? visual_width + 2 : logo_text.offsetWidth + 2;
                let height = width;
                let border_radius = width/2;
                let logo_background = this.props.logo_background;
                
                let style = `
                    width: ${width}px;
                    height: ${height}px;
                    color: white;
                    display: flex;
                    justify-content: center;
                    position: relative;
                    border: 1px solid #aaa;
                    border-radius: ${border_radius}px;
                    -webkit-border-radius: ${border_radius}px;
                    -moz-border-radius: ${border_radius}px;
                    background: ${logo_background};
                    text-align: center
                `;
                console.log(`Style Logo: ${style}`);
                logo.setAttribute('style', style);
                style = `
                    margin: 0 auto;
                    position: absolute;
                    top: 50%;
                    transform: translate(0, -50%)
                `;
                console.log(`Style Logo Text: ${style}`);
                logo_text.setAttribute('style', style);
            }
        }
    }
}

SiteLogo.propTypes = {
    logo_text: PropTypes.string
};

export default SiteLogo;