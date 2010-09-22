/* ================================
   Placeholder for input element

   by Niels 'That Guy' Groot Obbink
   that-guy.net          2009-12-26

   http://that-guy.net/copyright/
   --------------------------------
   version 1.0 - release
           1.1 - screw IE
           1.2 - minor stuff
           1.3 - double i var fix
           1.4 - works in IE now!
   ================================
*/





function addEvent(obj, type, fn)
{
   if(obj.attachEvent)
   {
      obj['e' + type + fn] = fn;
      obj[type + fn] = function()
      {
         obj['e' + type + fn](window.event);
      }
      obj.attachEvent('on' + type, obj[type + fn]);
   }else{
      obj.addEventListener(type, fn, false);
   }
}



function placePlaceHolders()
{
   var inp = document.createElement('input');
   if('placeholder' in inp)
   {
      return false;   /* bail, there is native placeholder support  */
   }

   var i, el = document.getElementsByTagName('input');
   var l = el.length;

   var normalColor = '#000', pholdColor = '#999';   /* edit this */


   for(i=0; i<l; i++)
   {
      if(el[i].getAttribute('placeholder'))
      {
         el[i].value = el[i].getAttribute('placeholder');
         el[i].style.color = pholdColor;

         addEvent(el[i], 'focus', function()
         {
            if(this.value == this.getAttribute('placeholder'))
            {
               this.value = '';
               this.style.color = normalColor;
             }
          });

         addEvent(el[i], 'blur', function()
         {
            if(this.value == '')
            {
               this.value = this.getAttribute('placeholder');
               this.style.color = pholdColor;
            }
         });
      }
   }
   return true;
}




/* do the magic */

placePlaceHolders();

