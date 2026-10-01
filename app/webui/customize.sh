# Runs once at install under KernelSU, APatch or Magisk; $MODPATH is the module.
# The app's root process (cli/, if any) ships in bin/.
if [ -d "$MODPATH/bin" ]; then
  set_perm_recursive "$MODPATH/bin" 0 0 0755 0755
fi
