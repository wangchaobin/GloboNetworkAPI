#
# Makefile for Network API project
#


help:
	@echo
	@echo "Network API"
	@echo
	@echo "Available target rules:"
	@echo "  docs       to create documentation files"
	@echo "  clean      to clean garbage left by builds and installation"
	@echo "  compile    to compile .py files (just to check for syntax errors)"
	@echo "  test       to execute all tests"
	@echo "  build      to build without installing"
	@echo "  install    to install"
	@echo "  dist       to create egg for distribution"
	@echo "  publish    to publish the package to PyPI"
	@echo "  start      to run project through docker compose"
	@echo "  stop       to stop all containers from docker composition"
	@echo "  fixture    to generate fixtures from a given model"
	@echo "  tests      to execute tests using containers. Use app variable"
	@echo


pip: # install pip libraries
	@pip install -r requirements.txt
	@pip install -r requirements_test.txt


db_reset: # drop and create database
	@[ -z $NETWORKAPI_DATABASE_PASSWORD ] && [ -z $NETWORKAPI_DATABASE_USER ] && [ -z $NETWORKAPI_DATABASE_HOST ] && mysqladmin -hlocalhost -uroot -f drop networkapi; true
	@[ -z $NETWORKAPI_DATABASE_PASSWORD ] && [ -z $NETWORKAPI_DATABASE_USER ] && [ -z $NETWORKAPI_DATABASE_HOST ] && mysqladmin -hlocalhost -uroot -f create networkapi; true
	@[ -n $NETWORKAPI_DATABASE_PASSWORD ] && [ -n $NETWORKAPI_DATABASE_USER ] && [ -n $NETWORKAPI_DATABASE_HOST ] && mysqladmin -hNETWORKAPI_DATABASE_HOST -uNETWORKAPI_DATABASE_USER -pNETWORKAPI_DATABASE_PASSWORD -f drop networkapi; true
	@[ -n $NETWORKAPI_DATABASE_PASSWORD ] && [ -n $NETWORKAPI_DATABASE_USER ] && [ -n $NETWORKAPI_DATABASE_HOST ] && mysqladmin -hNETWORKAPI_DATABASE_HOST -uNETWORKAPI_DATABASE_USER -pNETWORKAPI_DATABASE_PASSWORD -f create networkapi; true


run: # run local server
	@python manage.py runserver 0.0.0.0:8000 $(filter-out $@,$(MAKECMDGOALS))


shell: # run django shell
	@python manage.py shell_plus


clean:
	@echo "Cleaning..."
	@rm -rf build dist *.egg-info
	@rm -rf docs/_build
	@find . \( -name '*.pyc' -o -name '**/*.pyc' -o -name '*~' \) -delete


docs: clean
	@(cd docs && make html)


compile: clean
	@echo "Compiling source code..."
	@python -tt -m compileall .
	#@pep8 --format=pylint --statistics networkapiclient setup.py


test: compile
	@[ ! -z $(NETWORKAPI_DATABASE_PASSWORD) ] && [ ! -z $(NETWORKAPI_DATABASE_USER) ] && [ ! -z $(NETWORKAPI_DATABASE_HOST) ] && mysqladmin -h $(NETWORKAPI_DATABASE_HOST) -u $(NETWORKAPI_DATABASE_USER) -p $(NETWORKAPI_DATABASE_PASSWORD) -f drop if exists test_networkapi; true
	@[ -z $(NETWORKAPI_DATABASE_PASSWORD) ] && [ -z $(NETWORKAPI_DATABASE_USER) ] && [ -z $(NETWORKAPI_DATABASE_HOST) ] && mysql -u root -e "DROP DATABASE IF EXISTS test_networkapi;"; true
	@python manage.py test --traceback $(filter-out $@,$(MAKECMDGOALS))


install:
	@python setup.py install


build:
	@python setup.py build


dist: clean
	@python setup.py sdist


publish: clean
	@python setup.py sdist upload



#
# Containers based target rules
#

start: docker-compose.yml
	@docker-compose up --detach


stop: docker-compose.yml
	@docker-compose down --remove-orphans


logs:
	@docker logs --tail 100 --follow netapi_app


tests:
	@clear
	@echo "Running NetAPI tests.."
	time docker exec -it netapi_app ./fast_start_test_reusedb.sh ${app}


fixture:
ifeq (${model},)
	$(error Missing model. Usage: make fixture model=interface.PortChannel)
endif
	docker exec -it netapi_app django-admin.py dumpdata ${model}
