#### README  

(Last updated 25 Oct 2016)
  
thunar-sendto-shredder provides a right-click, context-menu shortcut for securely erasing files from within the Thunar file manager.  

To use it, open Thunar and right-click on a file or directory.  Select "Send To", and then "Shredder".  
  
To configure Settings, either click on its graphical shortcut from within Applications or use the commandline.
  
If it is run from the commandline like this:```thunar-sendto-shredder```, a dialog will pop up and offer a choice of settings to configure.  This includes choosing which overwrite method to use.  
This is also the default view if brought up from a graphical interface (i.e., from the XFCE control panel).  
  
It can also be brought up with a file or directory as an argument.  For example, to delete a directory "Trash" in foo's home directory:  <p><code>thunar-sendto-shredder ~foo/Trash</code></p>.  
  
It is recommended to always keep the Prompt setting enabled.  There is no recycle bin or trash can to bring back files that have been overwritten.

Note that while additional overwrites may provide extra security, more overwrites means the application will run slower and may slow down other applications in use.  
  
Also, the program "shred" - from which this program is based - does not
handle directories.  However, one of the options on the Settings interface
offers to rename and unlink an empty directory.  Recursive shredding may be
offered in the future.

Finally, don't forget to report bugs.  :)

#### DEPENDENCIES  

[Thunar](http://docs.xfce.org/xfce/thunar/start)  
[shred](http://www.gnu.org/software/coreutils/)

#### HOMEPAGE  
 
https://dave-theunsub.github.io/thunar-sendto-shredder/    

#### Thanks!  
  
Thanks to [Tango](http://tango.freedesktop.org/Tango_Icon_Library) for releasing their icons to the Public Domain.
  
&copy; Dave M, 0x6ADA59DE
@dave-theunsub
