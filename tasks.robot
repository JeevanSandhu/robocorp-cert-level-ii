*** Settings ***
Documentation     Orders robots from RobotSpareBin Industries Inc.
...               Saves the order HTML receipt as a PDF file.
...               Saves the screenshot of the ordered robot.
...               Embeds the screenshot of the robot to the PDF receipt.
...               Creates ZIP archive of the receipts and the images.
Library            RPA.Browser.Selenium    auto_close=${FALSE}
Library            RPA.HTTP
Library    RPA.Excel.Application
Library    RPA.Tables
Library    RPA.PDF
Library    RPA.Archive
Library    RPA.Dialogs
Library    RPA.Robocorp.Vault

*** Tasks ***
Order robots from RobotSpareBin Industries Inc
    Open the robot order website
    ${name}=    Get user's name
    ${csvlink}=    Get CSV file link from user    ${name}
    ${orders}=    Get orders    ${csvlink}
    FOR    ${row}    IN    @{orders}
        Close the annoying modal
        Fill the form    ${row}
        Wait Until Keyword Succeeds    5x    1s    Preview the robot
        Wait Until Keyword Succeeds    5x    1s    Submit the order
        ${pdf}=    Store the receipt as a PDF file    ${row}[Order number]
        ${screenshot}=    Take a screenshot of the robot    ${row}[Order number]
        Embed the robot screenshot to the receipt PDF file    ${screenshot}    ${pdf}
        Go to order another robot
    END
    # Create a ZIP file of the receipts
    [Teardown]    Close the browser

*** Keywords ***
Open the robot order website
    Open Available Browser    https://robotsparebinindustries.com/#/robot-order

Get orders
    [Arguments]    ${csvlink}
    # Download    https://robotsparebinindustries.com/orders.csv    overwrite=True
    Download    ${csvlink}    overwrite=True
    ${orders}=    Read table from CSV    orders.csv    header=True
    [Return]    ${orders}

Close the annoying modal
    Wait Until Page Contains Element    class:btn-dark
    Click Button    class:btn-dark

Fill the form
    [Arguments]    ${row}
    Select From List By Value    id:head    ${row}[Head]
    Select Radio Button    body    ${row}[Body]
    Input Text    xpath://input[@placeholder="Enter the part number for the legs"]    ${row}[Legs]
    Input Text    id:address    ${row}[Address]

Preview the robot
    Click Button    id:preview
    Wait Until Element Is Visible    id:robot-preview-image    timeout=1s

Submit the order
    Click Button    id:order
    Wait Until Element Is Visible    id:receipt

Go to order another robot
    Click Button    order-another

Store the receipt as a PDF file
    [Arguments]    ${order_num}
    ${filepath}    Set Variable    ${OUTPUT_DIR}${/}receipt_pdf${/}${order_num}.pdf
    ${html}=       Get Element Attribute    id:receipt    outerHTML
    Html To Pdf    ${html}    ${filepath}
    [Return]       ${filepath}

Take a screenshot of the robot
    [Arguments]    ${order_num}
    ${filepath}    Set Variable    ${OUTPUT_DIR}${/}screensots${/}${order_num}.png
    Screenshot    id:robot-preview-image    ${filepath}
    [Return]    ${filepath}

Embed the robot screenshot to the receipt PDF file
    [Arguments]    ${screenshot}    ${pdf}
    ${screenshot_list}    Create List    ${screenshot}:x=0,y=0
    Add Files To Pdf    files=${screenshot_list}    target_document=${pdf}    append=True


Close the browser
    Close Browser

Create a ZIP file of the receipts
    ${zip}    Set Variable    ${OUTPUT_DIR}${/}zipfolder.zip
    Archive Folder With Zip    ${OUTPUT_DIR}${/}receipt_pdf    ${zip}

Get user's name
    ${user}=    Get Secret    User
    [Return]    ${user}[name]

Get CSV file link from user
    [Arguments]    ${name}
    Add heading    Hi, ${name}! Please enter the CSV link
    Add text input    name=csvlink    label=CSV file link    placeholder=Please enter the link to download the csv file
    ${link}=    Run dialog
    [Return]    ${link}[csvlink]