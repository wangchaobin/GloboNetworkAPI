# -*- coding: utf-8 -*-
# Licensed to the Apache Software Foundation (ASF) under one or more
# contributor license agreements.  See the NOTICE file distributed with
# this work for additional information regarding copyright ownership.
# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
import logging

from django.forms.models import model_to_dict

from networkapi.admin_permission import AdminPermission
from networkapi.auth import has_perm
from networkapi.exception import InvalidValueError
from networkapi.grupo.models import GrupoError
from networkapi.grupo.models import UGrupo
from networkapi.grupo.models import UGrupoNotFoundError
from networkapi.infrastructure.xml_utils import dumps_networkapi
from networkapi.rest import RestResource
from networkapi.rest import UserNotAuthorizedError
from networkapi.usuario.models import Usuario
from networkapi.util import is_valid_int_greater_zero_param


class UserGetByGroupUserOutGroup(RestResource):

    log = logging.getLogger('UserGetByGroupUserOutGroup')

    def handle_get(self, request, user, *args, **kwargs):
        """Treat requests GET to get Group Equipment.

        URL: user/out/group/<id_ugroup>/
        """

        try:
            self.log.info('Get Users out group by ID Group User')

            id_ugroup = kwargs.get('id_ugroup')

            # User permission
            if not has_perm(user, AdminPermission.USER_ADMINISTRATION, AdminPermission.READ_OPERATION):
                self.log.error(
                    u'User does not have permission to perform the operation.')
                raise UserNotAuthorizedError(None)

            # Valid Group User ID
            if not is_valid_int_greater_zero_param(id_ugroup):
                self.log.error(
                    u'The id_ugroup parameter is not a valid value: %s.', id_ugroup)
                raise InvalidValueError(None, 'id_ugroup', id_ugroup)

            # Find Group User by ID to check if it exist
            UGrupo.get_by_pk(id_ugroup)

            users = Usuario.objects.exclude(grupos__id=id_ugroup)

            user_list = []
            for user in users:
                us = model_to_dict(user)
                user_list.append(us)

            user_map = dict()
            user_map['users'] = user_list

            return self.response(dumps_networkapi(user_map))

        except InvalidValueError, e:
            return self.response_error(269, e.param, e.value)

        except UserNotAuthorizedError:
            return self.not_authorized()

        except UGrupoNotFoundError:
            return self.response_error(180, id_ugroup)

        except GrupoError, e:
            return self.response_error(1)
