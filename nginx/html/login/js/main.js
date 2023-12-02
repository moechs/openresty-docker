
(function ($) {
    "use strict";

    $.base64.utf8encode = true;
    $.cookie.raw = true;
    var input = $('.validate-input .input100');

    $('.validate-form').on('submit',function(){
        var basicauth = $.base64.btoa($("#username").val().trim() + ":" + $("#password").val());
        $.cookie('basicauth', basicauth, { path: '/' });
        var check = true;

        for(var i=0; i<input.length; i++) {
            if(validate(input[i]) == false){
                showValidate(input[i]);
                check=false;
            }
        }
        return check;
    });


    $('.validate-form .input100').each(function(){
        $(this).focus(function(){
           hideValidate(this);
        });
    });

    function validate (input) {
        if($(input).attr('type') == 'username' || $(input).attr('name') == 'username') {
            if($(input).val().trim().match(/^([a-zA-Z0-9_\-\.]+)$/) == null) {
                return false;
            }
        }
        else {
            if($(input).val().trim() == ''){
                return false;
            }
        }
    }

    function showValidate(input) {
        var thisAlert = $(input).parent();

        $(thisAlert).addClass('alert-validate');
    }

    function hideValidate(input) {
        var thisAlert = $(input).parent();

        $(thisAlert).removeClass('alert-validate');
    }
    
    

})(jQuery);
