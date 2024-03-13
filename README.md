# Image Caustics
Turn an image into a normal map that refracts light in just the right way to create that image!

For a nice explanation of what's happening (and the inspiration for this), look at this video: https://m.youtube.com/watch?v=wk67eGXtbIw

Here's an example:

<video src="https://github.com/JulianBohne/ImageCaustics/assets/57051885/a94a3ccb-d4bf-4bfa-b880-db8e5ed37797" controls></video>

> Note: I'm not 100% convinced, that I'm calculating everything correctly. If you know a program where I can double check my results, that would be nice! (I couldn't get proper caustics to work in Blender with my crappy laptop.)

Here's the normal map corresponding to the eye (not obvious, right?! :D)

<img src="https://github.com/JulianBohne/ImageCaustics/assets/57051885/ce3afa87-3573-4b1f-82b6-5a3a68614e38" alt="Normal map of the eye image" width=500/>

## Usage
0. Make sure you got [processing](https://www.processing.org) installed (this was written in it).
1. Put your (grayscale) image that you want to convert into the `resources` folder of `ImageCausticsGenerator`.
2. Open the `ImageCausticsGenerator.pde` file and edit the `loadImage` line, so it loads your image instead of the example provided.
3. Press the play button in the top left and wait until the numbers in the console stop or the image animates back and forth between two states.
4. Copy paste the `normals.png` into the `resources` folder of `ImageCausticsViewer`.
5. Open the `ImageCausticsViewer.pde` file and make sure the `loadImage` line loads the correct normals.
6. Press the play button in the top left and you should be able to view the caustics and slightly rotate the virtual glass with your mouse.
    1. You can also move the glass closer and further from the screen with the up and down arrows.

## How does it work?
> Note: This is simplified
1. Figure out which light has to move where
    1. Start with a uniform light distribution
    2. Optimize according to the image horizontally and vertically
    3. Iterate until the mean movement of light goes up again (not quite sure why that happens yet, but it's a good indicator that it's done)
2. Calculate the normals from each movement
3. Simulate a uniform light distribution refracting through a glass plate

## Limitations
1. Holes can be difficult for the algorithm (see the circle/torus example image)
2. If there are multiple elements that can't reach each other by a single horizontal or vertical move, the brightness will probably be off
3. The images you get in the viewer are more fuzzy (see the dot example image for a big fail in that regard)
4. I'm not taking fresnel into account, so the light intensities might be a bit off (especially when roatating the glass in the viewer)
