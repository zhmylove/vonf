//
// TODO if it's start page, then make a websocket to instantly connect on adjacent connection

$(document).ready(function(){
   var connect_url = window.location.origin + "/c/" + $('#session_id').val();
   var factor = 3;
   var side = Math.min(Math.round($(window).width()/factor), Math.round($(window).height()/factor));
   new QRCode(document.getElementById("qr"), {
      text: connect_url,
      width: side,
      height: side,
      colorDark: "#060709",
      colorLight: "#ffffff",
      correctLevel : QRCode.CorrectLevel.L
   });

   $('#connect').click(function(){
      window.location.href = connect_url;
   });
   $('#end_session').click(function (e) {
      window.location.href = "/s/logout";
   });
});
