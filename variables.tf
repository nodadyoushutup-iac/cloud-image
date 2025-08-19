variable "cloud_init" {
  description = "Cloud-init configuration snippets"
  type = list(object({
    content_type = string
    datastore_id = string
    node_name    = string
    overwrite    = optional(bool, false)
    file_name    = string
    config = optional(object({
      hostname = optional(string)
      timezone = optional(string)
      mounts   = optional(list(list(string)))
      groups   = optional(list(string))
      users = optional(list(object({
        name                = string
        groups              = optional(list(string))
        shell               = optional(string)
        plain_text_passwd   = optional(string)
        sudo                = optional(string)
        lock_passwd         = optional(bool)
        ssh_import_id       = optional(list(string))
        ssh_authorized_keys = optional(list(string))
      })))
      package_update  = optional(bool)
      package_upgrade = optional(bool)
      packages        = optional(list(string))
      bootcmd         = optional(list(string))
      runcmd          = optional(list(string))
    }))
  }))
}

variable "virtual_machine" {
  description = "Virtual machine definitions"
  type = list(object({
    name      = string
    node_name = string
    agent = optional(object({
      enabled = optional(bool)
    }))
    bios = optional(string)

    cpu = optional(object({
      cores   = optional(number)
      sockets = optional(number)
      type    = optional(string)
    }))

    memory = optional(object({
      dedicated = optional(number)
      floating  = optional(number)
    }))

    disk = optional(object({
      datastore_id = optional(string)
      interface    = optional(string)
      iothread     = optional(bool)
      discard      = optional(string)
      size         = optional(number)
      file_id      = optional(string)
    }))

    initialization = optional(object({
      ip_config = optional(object({
        ipv4 = optional(object({
          address = optional(string)
          gateway = optional(string)
        }))
        ipv6 = optional(object({
          address = optional(string)
          gateway = optional(string)
        }))
      }))
      user_data_file_id = optional(string)
    }))

    network_device = optional(object({
      bridge   = optional(string)
      model    = optional(string)
      firewall = optional(bool)
      tag      = optional(number)
    }))

    vm_id = number
  }))
}
