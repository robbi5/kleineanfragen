document.documentElement.className += ' js';
new FontFaceObserver('Source Sans Pro')
  .check()
  .then(function(){
    document.documentElement.className += ' fonts-loaded';
  });