
function change_language()
{
    // append language menu
    var lg = '<ul id="language_menu">';
    var langs = $('#site_lang').attr('data-language');
    
    langs = langs.split('#');
    
    for(i=0; i<langs.length; i++){
        lg += '<li class="language_item"><a href="#">' + langs[i] + '</li></a>';
    }
    
    lg += '</ul>';
    $('#site_lang').append(lg);
    
    $('#site_lang').hover(
        function(){
            $('#language_menu').fadeToggle(700);
        },
        function(){
            $('#menu-main-menu').mouseout(
                function(){$('#language_menu').stop().fadeToggle(700);}
            );
        }
    );
}
