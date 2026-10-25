load("@ytt:data", "data")
load("@ytt:struct", "struct")

# ###########
# COMPONENTS
# ###########

# The controllers in the upstream manifest. `key` is the name of their section in the values, and `deployment`
# the name of their Deployment, ServiceAccount, and `app.kubernetes.io/component` label. All of them run in a
# `manager` container. `events` tells whether they send events to the notification controller.
components = [
  struct.encode({"key": "source_controller", "deployment": "source-controller", "events": True}),
  struct.encode({"key": "kustomize_controller", "deployment": "kustomize-controller", "events": True}),
  struct.encode({"key": "helm_controller", "deployment": "helm-controller", "events": True}),
  struct.encode({"key": "notification_controller", "deployment": "notification-controller", "events": False}),
  struct.encode({"key": "image_reflector_controller", "deployment": "image-reflector-controller", "events": True}),
  struct.encode({"key": "image_automation_controller", "deployment": "image-automation-controller", "events": True}),
  struct.encode({"key": "source_watcher", "deployment": "source-watcher", "events": True}),
]

def component_values(component):
  return getattr(data.values, component.key)
end

# The source controller is always deployed, since all the others consume its artifacts.
def is_enabled(component):
  return component.key == "source_controller" or component_values(component).enabled
end

def enabled_components():
  return [component for component in components if is_enabled(component)]
end

# The labels selecting the Pods of a component, as in the upstream Deployments.
def component_selector(component):
  return {"app": component.deployment}
end

# ###########
# FLAGS
# ###########

# The values of the logging flags, which Flux calls `console` and `json`.
_log_encodings = {"text": "console", "json": "json"}

# The flags computed from the package values. `<component>.args` is merged on top of them.
def component_args(component):
  logging = data.values.observability.logging
  args = {
    "log-level": logging.level,
    "log-encoding": _log_encodings[logging.format],
  }

  # Without the notification controller, there's nobody to send the events to.
  if component.events:
    if data.values.notification_controller.enabled:
      args["events-addr"] = "http://notification-controller." + data.values.namespace + ".svc.cluster.local./"
    else:
      args["events-addr"] = None
    end
  end

  for name, value in struct.decode(component_values(component).args).items():
    args[name.lstrip("-")] = value
  end
  return args
end

def _format(value):
  if type(value) == "bool":
    return "true" if value else "false"
  end
  return str(value)
end

# Merges the given flags into the upstream ones, keeping their order. New flags are appended,
# and flags set to null are removed. Upstream flags without a value, like `--enable-leader-election`, are kept as they are.
def _merge_args(upstream, overrides):
  flags = {}
  for arg in upstream:
    name, separator, value = arg.lstrip("-").partition("=")
    flags[name] = value if separator else None
  end
  for name, value in overrides.items():
    if value == None:
      flags.pop(name, None)
    else:
      flags[name] = _format(value)
    end
  end
  return ["--" + name if value == None else "--" + name + "=" + value for name, value in flags.items()]
end

# The `via` function of the overlays replacing the upstream container args.
def args_merger(overrides):
  return lambda left, _: _merge_args(left, overrides)
end
