# Project of EPFL Embedded system

We build a monitor system with a camera and a LCD display. The system interfere with peripherals by a DMA unit, which efficiently fetch or write data to memory while simultaneously streaming the data from/to the application-specific interface which are targeting (the camera, LCD, or VGA controller).

The camera and LCD display is configured before use with I2C. The transmission between camera-CPU, and CPU-LCD are controlled by Avalon bus. 


<h5 align="center"> <img width="500" alt="Screen Shot 2022-08-23 at 10 16 45 AM" src="https://user-images.githubusercontent.com/68586310/186108210-cb213188-9b40-4724-b498-aa9899ad9bbc.png"> </h5>
<h6 align="center">Fig 1. Architecture of camera module</h6>

<h5 align="center"> <img width="500" alt="Screen Shot 2022-08-23 at 10 17 34 AM" src="https://user-images.githubusercontent.com/68586310/186108383-0967b584-91aa-4135-93e5-120283c6f249.png"> </h5>
<h6 align="center">Fig 2. Architecture of LCD module</h6>
