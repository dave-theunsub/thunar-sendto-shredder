README
------
(Last updated 6 Oct 2016)
  
thunar-sendto-shredder provides a right-click, context-menu shortcut for securely erasing files from within the Thunar file manager.  

To use it, open Thunar and right-click on a file or directory.  Select "Send To", and then "thunar-sendto-shredder".  
  
To configure Settings, either click on its graphical shortcut from within Applications or use the commandline.
  
If it is run from the commandline like this: <p><code>thunar-sendto-shredder</code></p>, a dialog will pop up and offer a choice of settings to configure.  This includes choosing which overwrite method to use.  
This is also the default view if brought up from a graphical interface (i.e., from Applications).  
  
It can also be brought up with a file or directory as an argument.  For example, to delete a directory "Trash" in foo's home directory:  <p><code>thunar-sendto-shredder ~foo/Trash</code></p>.  
  
It is recommended to always keep the Prompt setting enabled.  There is no recycle bin or trash can to bring back files that have been overwritten.

Note that while additional overwrites may provide extra security, more overwrites means the application will run slower and may bog down other applications in use.

DEPENDENCIES
------------

Thunar

https://dave-theunsub.github.io/thunar-sendto-shredder/    
  
&copy; Dave M, 0x6ADA59DE
