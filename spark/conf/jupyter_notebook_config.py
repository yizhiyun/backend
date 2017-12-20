# Configuration file for jupyter-notebook.
# Set ip to '*' to bind on all interfaces (ips) for the public server
c.NotebookApp.ip = '*'
c.NotebookApp.password = u'sha1:dd2f2b160b14:2425668abef6e6c9786cac2bd3add9cf40a362df'
c.NotebookApp.open_browser = False

# Whether to allow the user to run the notebook as root.
c.NotebookApp.allow_root = True

# The port the notebook server will listen on.
c.NotebookApp.port = 8888