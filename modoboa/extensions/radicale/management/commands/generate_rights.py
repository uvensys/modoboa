import os
import datetime
from optparse import make_option

from django.core.management.base import BaseCommand

from modoboa.core.management.commands import CloseConnectionMixin
from modoboa.core.models import User
from modoboa.lib import parameters
from modoboa.extensions.admin.models import Domain
from ...models import (
    AccessRule
)
from ...modo_extension import Radicale


class Command(BaseCommand, CloseConnectionMixin):
    help = "Generate Radicale rights file"

    option_list = BaseCommand.option_list + (
        make_option('--force',
                    action='store_true',
                    default=False,
                    help='Force generation of rights file'),
    )

    def _generate_acr(self, name, user, collection, perm="rw", comment=None):
        """Write a new access control rule to the config file.
        """
        if comment is not None:
            self._cfgfile.write("\n# %s" % comment)
        self._cfgfile.write("""
[%s]
user = %s
collection = %s
permission = %s
""" % (name, user, collection, perm)
        )

    def _user_access_rules(self):
        """Create user access rules.
        """
        for acr in AccessRule.objects.select_related().all():
            section = "%s-to-%s-acr" % (
                acr.mailbox, acr.calendar
            )
            permission = ""
            if acr.read:
                permission += "r"
            if acr.write:
                permission += "w"
            self._generate_acr(
                section, acr.mailbox.full_address, acr.calendar.path,
                permission,
            )

    def _super_admin_rules(self):
        """Generate access rules for super administrators.
        """
        for sa in User.objects.filter(is_superuser=True):
            section = "sa-%s-acr" % sa.username
            self._generate_acr(
                section, sa.username, ".*"
            )

    def _domain_admin_rules(self):
        """Generate access rules for domain adminstrators.
        """
        for da in User.objects.filter(groups__name="DomainAdmins"):
            for domain in Domain.objects.get_for_admin(da):
                section = "da-%s-to-%s-acr" % (da.email, domain.name)
                self._generate_acr(
                    section, da.email, "%s/user/.*" % domain.name
                )

    def _generate_file(self, target):
        """
        A user must not declare a rule for his direct admin!
        """
        self._cfgfile = open(target, "w")
        self._cfgfile.write("""# Rights management file for Radicale
# This file was generated by Modoboa on %s
# DO NOT EDIT MANUALLY!
        """ % datetime.datetime.today())

        allow_calendars_administration = parameters.get_admin(
            "ALLOW_CALENDARS_ADMINISTRATION", app="radicale")
        if allow_calendars_administration == "yes":
            self._super_admin_rules()
            self._domain_admin_rules()

        self._generate_acr(
            "domain-shared-calendars", r"^(.+)@(.+)$", r"{1}/shared/.+$",
            comment="Access rule to domain shared calendars"
        )
        self._generate_acr(
            "owners-access", r"^(.+)@(.+)$", r"{1}/user/{0}/.+$",
            comment="Read/Write permission for calendar owners"
        )

        self._user_access_rules()
        self._cfgfile.close()

    def handle(self, *args, **options):
        """Command entry point."""
        Radicale().load()
        path = parameters.get_admin("RIGHTS_FILE_PATH", app="radicale")
        if not options["force"]:
            try:
                mtime = datetime.datetime.fromtimestamp(
                    int(os.path.getmtime(path))
                )
            except OSError:
                pass
            else:
                if not AccessRule.objects.filter(last_update__gt=mtime).count():
                    return
        self._generate_file(path)
