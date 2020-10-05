# Xeed Agent - SLT to HTTP
## Introduction
* Xeed SLT Agent is a plugin of SAP SLT (Landscape Transformation) Server. It can copy the output flow of SLT Server in a [X-I compatible HTTP Flow](https://github.com/X-I-A/X-I-Protocol/blob/main/HTTP_AGENT.md).
* The output HTTP flow can be caught by other compatible Xeed Agents in order to put the live data streaming into Insight Layer
* Example: [Http to Pubsub](https://github.com/X-I-A/Xeed_http_pubsub)
* This plugin is one of the building block of the X-I-A Architecture.
* Xeed - Insight - Analysis (X-I-A Architecture) is a full scope data solution. Connecting to [my profile @ Linkedin](https://www.linkedin.com/in/xia-chen-soral/) to get the latest update
## Quick Start Guide
### Installation
* From Github: Cloning the repo by using [abapGit](https://github.com/abapGit/abapGit)
* From Transport Order: All of the released transport order could be found under each release
### Customization
* The SLT Server should have been correctly configured
* Transaction SM59: Creating an RFC Connection Type G -> That's the destination of your SLT to HTTP flow
* Transaction FILE: Creating a logical location to hold the flow in the case of network issues
* Resend Job Creation: Using the standard report RSBTONEJOB2 to schedule the resend report Z_XEED_RESEND
### Adding required Tables
Launching the report Z_XEED_OPERATION:
* Mass Transfer ID: Could be found by transaction LTRS
* Table Name: Using the multiple selection to do massive operation (range is not supported yet.)
* HTTP Destination and File Location should be the one of the step Customization
* Source or Result Flag: S = Source and R = Result
* Max Frag Size: The limitation of HTTP body. Once exceeded, the data will be splitted to several http message.
