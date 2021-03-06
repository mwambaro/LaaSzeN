
function responsive_david_egan_menu() 
{

// Responsive Menu
	// prepend menu icon 
			$('#nav_wrap').prepend('<div id="menu_icon">Menu</div>');
			$("#menu_icon").hover(
			    function(){
			        $(this).css('text-decoration', 'underline');
			    },
			    function(){
			        $(this).css('text-decoration', 'none');
			    }
			);
	
	// toggle nav
			$("#menu_icon").on(
			    "click", 
			    function(){
			        $('#menu-main-menu').stop().fadeToggle(700);
			    }
			);

// Back to Top Navigation
	
	// Show or hide the sticky footer button
			$(window).scroll(function() {
				if ($(this).scrollTop() > 200) {
					$('.go_top').fadeIn(200);
				} else {
					$('.go_top').fadeOut(200);
				}
			});
	
	// Animate the scroll to top
			$('.go_top').click(function(event) {
				event.preventDefault();
				
				$('html, body').animate({scrollTop: 0}, 300);
			})	
			
// Show hide content wrapped in dd tags

		$("#faqs dd").hide();
		$("#faqs dt").click(function () {
				$(this).next("#faqs dd").slideToggle(500);
				$(this).toggleClass("expanded");
			});
			
// Make the class overlay clickable 

		$(".overlay").click(function(){
			window.location=$(this).find("a").attr("href"); 
			return false;
		});

}
