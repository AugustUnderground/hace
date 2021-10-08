import setuptools
 
package_name = 'hace'

with open('README.md', 'r') as fh:
    long_description = fh.read()

with open('requirements.txt', 'r') as req:
    requirements = req.read().splitlines()
 
setuptools.setup( name                          = package_name
                , version                       = '0.0.1'
                , author                        = 'Yannick Uhlmann, Matthias Schweikardt'
                , author_email                  = 'yannick.uhlmann@reutlingen-university.de'
                , description                   = 'Analog Circuit Characterization Environment'
                , long_description              = long_description
                , long_description_content_type = 'text/markdown'
                , url                           = 'https://github.com/augustunderground/hace'
                , packages                      = setuptools.find_packages()
                , classifiers                   = [ 'Development Status :: 2 :: Pre-Alpha'
                                                  , 'Programming Language :: Python :: 3'
                                                  , 'Operating System :: POSIX :: Linux' ]
                , python_requires               = '>=3.9'
                , install_requires              = requirements
                #, entry_points                  = { 'console_scripts': [ 'FIXME' ]}
                , package_data                  = { '': ['*.hy', '__pycache__/*']}
                , )
