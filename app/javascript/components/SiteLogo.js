import React from "react"
import PropTypes from "prop-types"

class SiteLogo extends React.Component {
    render(){      
        return(
            <div id="site-logo">
                <h1 id="site-logo-text"> {this.props.logo_text}  </h1>      
            </div>
        );
    }

    componentDidMount(){
        this.hideRulerElement();
        this.applyStyleToLogo();
    }
    
    hideRulerElement(){
        let ruler = document.getElementById('ruler');
        if(ruler){
            let style = `
                visibility: hidden;
                white-space: nowrap
            `;
            ruler.setAttribute('style', style);
        }
    }

    visualLength(text){
        let width = 0;
        let ruler = document.getElementById('ruler');
        if(ruler){
            ruler.innerHTML = text;
            width = ruler.offsetWidth;
        }

        return width;
    }

    applyStyleToLogo(){
        let logo_text = document.getElementById('site-logo-text');
        if(logo_text){
            let visual_width = this.visualLength(logo_text.innerText);
            let logo = document.getElementById('site-logo');
            if(logo){
                let width = visual_width ? visual_width + 2 : logo_text.offsetWidth + 2;
                let height = width;
                let border_radius = width/2;
                
                let style = `
                    width: ${width}px;
                    height: ${height}px;
                    display: flex;
                    justify-content: center;
                    position: relative;
                    border: 1px solid #aaa;
                    border-radius: ${border_radius}px;
                    -webkit-border-radius: ${border_radius}px;
                    -moz-border-radius: ${border_radius}px;
                    background: #f8f8f8;
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