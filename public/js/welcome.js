$(document).ready(function(){
   $('#id').val('');
   $('#form').submit(
      function () {
         // TODO validate $('#id') here
         window.location.href = "/c/" + $('#id').val();
         return false;
      });
});
