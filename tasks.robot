*** Settings ***
Documentation       Orders robots from RobotSpareBin Industries Inc.
...                 Saves the order HTML receipt as a PDF file.
...                 Saves the screenshot of the ordered robot.
...                 Embeds the screenshot of the robot to the PDF receipt.
...                 Creates ZIP archive of the receipts and the images.

Library             RPA.Browser.Selenium    # auto_close=${False}
Library             RPA.HTTP
Library             RPA.Tables
Library             RPA.Robocorp.WorkItems
Library             RPA.PDF
Library             RPA.FileSystem
Library             RPA.RobotLogListener
Library             RPA.Archive


*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Clear outputs for clean run
    Open the robot order website
    Download order csv file
    Close Modal
    ${orders}=    Get orders
    FOR    ${order}    IN    @{orders}
        Wait Until Keyword Succeeds    20x    2s    Loop orders    ${order}
    END
    Create ZIP package from PDF files


*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Download order csv file
    Download    https://robotsparebinindustries.com/orders.csv    overwrite=${True}

Get orders
    ${orders}=    Read table from CSV    orders.csv    header=${True}
    RETURN    ${orders}

Loop orders
    [Arguments]    ${order}
    Select From List By Value    id:head    ${order}[Head]
    Click Element    id-body-${order}[Body]
    Input Text    css:.form-group [type='number']    ${order}[Legs]
    Input Text    address    ${order}[Address]
    Click Button    preview
    Wait Until Element Is Visible    css:#robot-preview-image img:nth-of-type(3)    10s
    Check and Create Directory screenshots
    Check and Create Directory orders
    Click Button    order
    Wait Until Element Is Visible    order-completion    5s
    Store order receipt as PDF    ${order}
    Store robot image in PDF    ${order}
    Click Button    order-another
    Close Modal

Close Modal
    Click Button    css:.modal-dialog button.btn.btn-dark

Store order receipt as PDF
    [Arguments]    ${order}
    ${path}=    Screenshot
    ...    id:receipt
    ...    ${OUTPUT_DIR}${/}screenshots${/}orders${/}order_${order}[Order number].png
    ${file}=    Create List
    ...    ${path}
    Add Files To Pdf
    ...    ${file}
    ...    target_document=${OUTPUT_DIR}${/}orders${/}Order no_${order}[Order number].pdf

Store robot image in PDF
    [Arguments]    ${order}
    ${path}=    Screenshot
    ...    id:robot-preview-image
    ...    ${OUTPUT_DIR}${/}screenshots${/}robots${/}robot_${order}[Order number].png
    ${file}=    Create List
    ...    ${path}

    Add Files To Pdf
    ...    ${file}
    ...    target_document=${OUTPUT_DIR}${/}orders${/}Order no_${order}[Order number].pdf    append=${True}

Check and Create Directory orders
    ${directory_exists}=    Does Directory Exist    ${OUTPUT_DIR}${/}orders${/}
    IF    not ${directory_exists}
        Create Directory    ${OUTPUT_DIR}${/}orders${/}
    END

Check and Create Directory screenshots
    ${directory_exists}=    Does Directory Exist    ${OUTPUT_DIR}${/}screenshots${/}
    IF    not ${directory_exists}
        Create Directory    ${OUTPUT_DIR}${/}screenshots${/}
    END

Clear outputs for clean run
    ${directory_orders_exists}=    Does Directory Exist    ${OUTPUT_DIR}${/}orders${/}
    ${directory_screenshots_exists}=    Does Directory Exist    ${OUTPUT_DIR}${/}screenshots${/}
    ${orders_file_exists}=    Does File Exist    orders.csv
    ${directory_screenshots_orders_exists}=    Does Directory Exist    ${OUTPUT_DIR}${/}screenshots${/}orders${/}
    ${directory_screenshots_robots_exists}=    Does Directory Exist    ${OUTPUT_DIR}${/}screenshots${/}robots${/}
    ${order_zip_file_exists}=    Does File Exist    ${OUTPUT_DIR}${/}orders.zip

    IF    ${directory_orders_exists}
        ${files}=    List Files In Directory    ${OUTPUT_DIR}${/}orders${/}
        FOR    ${file}    IN    @{files}
            Remove File    ${file}
        END
        Remove Directory    ${OUTPUT_DIR}${/}orders${/}
    END

    IF    ${directory_screenshots_exists}
        IF    ${directory_screenshots_orders_exists}
            ${files}=    List Files In Directory    ${OUTPUT_DIR}${/}screenshots${/}orders${/}
            FOR    ${file}    IN    @{files}
                Remove File    ${file}
            END
            Remove Directory    ${OUTPUT_DIR}${/}screenshots${/}orders${/}
        END

        IF    ${directory_screenshots_robots_exists}
            ${files}=    List Files In Directory    ${OUTPUT_DIR}${/}screenshots${/}robots${/}
            FOR    ${file}    IN    @{files}
                Remove File    ${file}
            END
            Remove Directory    ${OUTPUT_DIR}${/}screenshots${/}robots${/}
        END

        Remove Directory    ${OUTPUT_DIR}${/}screenshots${/}
    END

    IF    ${orders_file_exists}    Remove File    orders.csv

    IF    ${order_zip_file_exists}    Remove File    ${OUTPUT_DIR}${/}orders.zip

Create ZIP package from PDF files
    Archive Folder With Zip    ${OUTPUT_DIR}${/}orders${/}    ${OUTPUT_DIR}${/}orders.zip
