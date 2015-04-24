
var id_latest_event_target = '';

function scroll_into_view(id)
{
    if(id){
        var fooOffset = jQuery('#'+id).offset();
        destination = fooOffset.top;
        jQuery(document).scrollTop(destination);
    }
}

// url: 'URI #id' where id is the identifier of the html data to
//      extract and save inside the element with id 'rcv_elt_id'
function fetch_data(rcv_elt_id, url)
{
    if(!rcv_elt_id || !url){
        return;
    }
    
    // fetch data
    $('#'+rcv_elt_id).load(
        url, function(){
            scroll_into_view(rcv_elt_id);
            on_click_next_prev_navs(); // rebind events because of
                                       // newly added ones, else lost listening.
        }
    );
}

function on_click(id, rcv_elt_id, url)
{
    $('#'+id).click(
        function(){
            fetch_data(rcv_elt_id, url);
        }
    );
}

function on_click_next_prev_navs()
{
    on_click(
        'next_slide_top', 'slides', 
        '/world_citizen/next_slide #body_data'
    );
    on_click(
        'prev_slide_top', 'slides', 
        '/world_citizen/prev_slide #body_data'
    );
    
    on_click(
        'next_slide_bottom', 'slides', 
        '/world_citizen/next_slide #body_data'
    );
    on_click(
        'prev_slide_bottom', 'slides', 
        '/world_citizen/prev_slide #body_data'
    );
    
    on_click(
        'next_ann', 'ann', 
        '/world_citizen/next_ann #body_data'
    );
    on_click(
        'prev_ann', 'ann', 
        '/world_citizen/prev_ann #body_data'
    );
    
    on_click(
        'next_motto', 'ex', 
        '/world_citizen/next_motto #body_data'
    );
    on_click(
        'prev_motto', 'ex', 
        '/world_citizen/prev_motto #body_data'
    );
}
