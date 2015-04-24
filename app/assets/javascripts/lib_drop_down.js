

function set_menu_bar_width()
{
    var width = (($('body').width() * 90)/100).toFixed();
    if(width < 125){
        $('div.div_dd_box').css('width', width + 'px');
    }
}

function start_off_drop_down()
{   
    // Initialize.
    // Does element exist?
    if (!$('ul.dropdown').length){
        // If not, exit.
        return;
    }
    
    // Add listener for hover.
    $('ul.dropdown li.ddheader').hover(
        function() {
            // Show subsequent <ul>.
            $(this).find('ul').fadeIn(1);
        },
        function() {
            // Hide subsequent <ul>.
            $(this).find('ul').hide();
        }
    );
}
