#!/usr/bin/env python3

import time

from selenium.common.exceptions import NoSuchElementException
from selenium import webdriver
from selenium.webdriver.chrome.options import Options  


def getCredential(
    challenge,
    host="federcard-password-generator.firebaseapp.com",
    driverExecutablePath="/usr/lib/firefox/geckodriver"
):

    """    options = Options()
    options.add_argument("--incognito")
    options.add_argument("--kiosk")"""

    driver = webdriver.Firefox(
        executable_path=driverExecutablePath
#        firefox_options=options
    )

    driver.get("http://%s/index.html#%s" % (host, challenge))

    credential = None
    while True:
        time.sleep(1)
        try:
            element = driver.find_element_by_id('credential')
        except NoSuchElementException:
            continue
        except Exception as e:
            print(e)
            return None

        ready = element.get_attribute("data-ready")
        if not ready: continue

        credential = element.get_attribute("textContent")
        break
    driver.quit()
    return credential

