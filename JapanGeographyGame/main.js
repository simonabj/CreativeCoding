// I have uploaded the GeoJSON file describing the first-level administrative divisions of Japan to my GitHub repository.
// The following code fetches the data from the URL and stores it in the japanData variable.
const dataURL = "https://raw.githubusercontent.com/simonabj/CreativeCoding/main/JapanGeographyGame/First-level_Administrative_Divisions_2015.json"
const dataRequest = new XMLHttpRequest(); // Start by creating a new XMLHttpRequest object
dataRequest.open('GET', dataURL, false);  // Then tell it to fetch the data from the URL while being synchronous
dataRequest.send(null);
let japanData = JSON.parse(dataRequest.responseText); // When the data is received, parse it to JSON

// Så laster vi inn data om grensene til prefekturer. Dette er en annen fil som også ligger på GitHub.
const borderDataURL = "https://raw.githubusercontent.com/simonabj/CreativeCoding/main/JapanGeographyGame/prefecture_borders.json"
const borderDataRequest = new XMLHttpRequest();
borderDataRequest.open('GET', borderDataURL, false);
borderDataRequest.send(null);
let borderData = JSON.parse(borderDataRequest.responseText);

/*
 * ====================================================================================================
 *  
 *                                 HTML ELEMENTS / DOM / VARIABLES
 * 
 * ====================================================================================================
*/

const canvasEl = document.getElementById('canvas');
const ctx = canvasEl.getContext('2d');
const prefectureListEl = document.getElementById('prefList');
const prefecturePickerEl = document.getElementById('prefPicker');
const addButtonEl = document.getElementById('addBtn');

const resolution = { x: 900, y: 900 };
canvasEl.width = resolution.x;
canvasEl.height = resolution.y;
let canvas_aspect = resolution.x / resolution.y;

let prefecturesToDraw = [];
let featureMap = createFeatureMap();

/*
 * ====================================================================================================
 *
 *                                           GAME VARIABLES
 * 
 * ====================================================================================================
*/

// PrefecturePathLength er antall prefekturer koblet sammen for 1 runde. Jo færre prefekturer, jo
// enklere blir runden. Denne skal kunne styres av brukeren
let PrefecturePathLength = 4;   

// Current path er en liste over prefekturer som spilleren har valgt. 
let currentPath = [];

// chosenButNotConnected er en liste over prefekturer som spilleren har valgt men som ikke er koblet sammen med
// noen andre prefekturer i currentPath. Dette er for å holde på prefekturer som spilleren har valgt men som kan
// bli koblet sammen med andre prefekturer i senere.
let chosenButNotConnected = [];

// optimalPaths er en liste over alle mulige kombinasjoner av prefekturer som spilleren kan velge som gir mest poeng.
// hver vei definert i optimalPaths er garantert og være PrefecturePathLength lang. Brukes også tilslutt for å 
// finne ut om spilleren har valgt en av de optimale veiene.
let optimalPaths = [];

/*
 * ====================================================================================================
 *
 *                                              GAME CODE
 * 
 * ====================================================================================================
*/

// Følgende kjører kun 1 gang når siden lastes inn, uavhengig om spiller starter en ny runde
ctx.imageSmoothingEnabled = false; // This will make the canvas not smooth out the lines when drawing
ctx.fillStyle = "black"; // Set the fill color to black

// Create options for the select element
for (let prefectureName in featureMap) {
    let new_option = document.createElement('option');
    new_option.value = featureMap[prefectureName];
    new_option.textContent = prefectureName;
    prefecturePickerEl.appendChild(new_option);
}

function startRunde() {

}


/*
 * ====================================================================================================
 *
 *                                        EVENT LISTENERS
 * 
 * ====================================================================================================
*/

addButtonEl.addEventListener('click', () => {
    let selectedFeatureIndex = prefecturePickerEl.value;
    // Only add the feature if it's not already in the list
    if (!prefecturesToDraw.includes(selectedFeatureIndex)) {
        createPrefectureListItem(selectedFeatureIndex)
        addPrefecture(selectedFeatureIndex);
        drawPrefectures();
    }
});


/* 
 * ====================================================================================================
 *
 *                                         HELPER FUNCTIONS 
 * 
 * ==================================================================================================== 
*/

// This function creates a new list item in the prefectureListEl and adds an event listener to remove it when clicked.
function createPrefectureListItem(featureIndex) {
    let listItem = document.createElement('li');
    listItem.textContent = japanData.features[featureIndex].properties.name_1;
    listItem.classList.add('prefListItem');
    listItem.addEventListener('click', () => {
        listItem.parentNode.removeChild(listItem);
        removePrefecture(featureIndex);
        drawPrefectures();
    });

    prefectureListEl.appendChild(listItem);
}

// Lag en liste med alle prefekturer som er akuratt N antall steg unna start. Siden grensene er en syklisk graf, må
// vi også ta hensyn til at vi ikke går tilbake i ring. Dette er da altså et bredde-først-søk.
function getNStepsAway(start, N) {
    let queue = [start];
    let visited = new Set([start]);
    let distance = {};
    distance[start] = 0;

    while (queue.length > 0) {
        let current = queue.shift();
    
        // Siden vi gjør bredde-først-søk, vil vi alltid finne den korteste veien først.
        // Altså kan vi avslutte søket når vi finner en node som er lenger enn N steg unna start.
        if (distance[current] > N) { 
            break;
        }

        for (let neighbor of borderData[current]) {
            if (!visited.has(neighbor)) {
                visited.add(neighbor);
                queue.push(neighbor);
                distance[neighbor] = distance[current] + 1;
            }
        }
    }

    // Hent så ut alle nodene som er N steg unna start
    return Object.keys(distance).filter(node => distance[node] === N);
}


// Because the points are in geographic coordinates, we need to convert them to canvas coordinates.
// This is done by getting the extent of the possible coordinates and then scaling the points to fit the canvas.
function convertToCanvasCoords(long, lat, bbox = japanData.bbox) {
    let width = canvasEl.width;
    let height = canvasEl.height;

    // Subtract the minimum form x and y to get a value between 0 and the maximum
    // Then divide by the maximum (also subtracting the minimum) to get a value between 0 and 1
    // Lastly, multiply by the width and height to get a value between 0 and the width/height
    let x = (long - bbox[0]) / (bbox[2] - bbox[0]) * width;
    let y = height - (lat - bbox[1]) / (bbox[3] - bbox[1]) * height;
    return [x, y];
}

// Simply return the bounding box of a feature
function getFeatureBBox(featureIndex) {
    let minX = Infinity;
    let minY = Infinity;
    let maxX = -Infinity;
    let maxY = -Infinity;

    // For each polygon in the MultiPolygon ...
    for (let feature_i of japanData.features[featureIndex].geometry.coordinates) {
        // ... For each point in the polygon boundry ...
        for (let p of feature_i[0]) {
            minX = Math.min(minX, p[0]);
            minY = Math.min(minY, p[1]);
            maxX = Math.max(maxX, p[0]);
            maxY = Math.max(maxY, p[1]);
        }
    }
    return [minX, minY, maxX, maxY];
}

// Returns the number of sub-features in a feature (i.e. the number of polygons in a MultiPolygon)
function numSubFeatures(featureIndex) {
    return japanData.features[featureIndex].geometry.coordinates.length;
}

// Gets the bounding box of all the features in the prefecturesToDraw array
// and creates a new bounding box that surrounds all of them.
function surroundingBBox() {
    let [minX, minY, maxX, maxY] = [Infinity, Infinity, -Infinity, -Infinity]; // Same as above, but shorter
    for (let featureIndex of prefecturesToDraw) {
        let bbox = getFeatureBBox(featureIndex);
        minX = Math.min(minX, bbox[0]);
        minY = Math.min(minY, bbox[1]);
        maxX = Math.max(maxX, bbox[2]);
        maxY = Math.max(maxY, bbox[3]);
    }
    return [minX, minY, maxX, maxY];
}

// Streches the bounding box to fit the aspect ratio of the canvas
function normalizeBBox(bbox) {
    let bbox_aspect = (bbox[2] - bbox[0]) / (bbox[3] - bbox[1]);
    let bbox_width = bbox[2] - bbox[0];
    let bbox_height = bbox[3] - bbox[1];
    let bbox_center_x = (bbox[2] + bbox[0]) / 2;
    let bbox_center_y = (bbox[3] + bbox[1]) / 2;

    if (bbox_aspect > canvas_aspect) {
        bbox_height = bbox_width / canvas_aspect;
    } else {
        bbox_width = bbox_height * canvas_aspect;
    }
    return [bbox_center_x - bbox_width / 2, bbox_center_y - bbox_height / 2, bbox_center_x + bbox_width / 2, bbox_center_y + bbox_height / 2];
}

// Constructs a map of the features in the GeoJSON data,
// where the key is the name of the feature and the value 
// is the index of the feature in the data.
// Example: featureMap["Saitama"] = 34
function createFeatureMap() {
    let featureMap = {}
    for (let i = 0; i < japanData.features.length; i++) {
        let feature = japanData.features[i];
        let name = feature.properties.name_1;
        featureMap[name] = i;
    }
    return featureMap;
}

// The drawFeature function will take an index of a feature in the GeoJSON data and draw it on the canvas.
function addPrefecture(featureIndex) {
    prefectureName = japanData.features[featureIndex].properties.name_1;
    console.log(`Adding ${prefectureName} to the list of prefectures to draw`);
    prefecturesToDraw.push(featureIndex);
}

function removePrefecture(featureIndex) {
    prefecturesToDraw = prefecturesToDraw.filter((index) => index !== featureIndex);
    console.log(`Removing ${japanData.features[featureIndex].properties.name_1} from the list of prefectures to draw`);
}

function drawPrefectures() {
    // Clear the canvas
    ctx.clearRect(0, 0, canvasEl.width, canvasEl.height);

    let bbox = surroundingBBox();
    let bbox_aspect = (bbox[2] - bbox[0]) / (bbox[3] - bbox[1]);
    console.log("Bounding box aspect ratio: " + bbox_aspect);
    console.log("Canvas aspect ratio: " + canvas_aspect);

    bbox = normalizeBBox(bbox);
    bbox_aspect = (bbox[2] - bbox[0]) / (bbox[3] - bbox[1]);
    console.log("Normalized bounding box aspect ratio: " + bbox_aspect);

    // If the bounding box is wider than the canvas, we need to scale the y-coordinates of the bbox
    // bbox = bbox_aspect > canvas_aspect ? [bbox[0], bbox[1], bbox[2], bbox[1] + (bbox[2] - bbox[0]) / canvas_aspect] : bbox;

    // For every feature in the prefecturesToDraw array, draw it on the canvas
    for (let featureIndex of prefecturesToDraw) {

        // The coordinates are stored in the geometry.coordinates property, and is a MultiPolygon.
        // Lets start by drawing the first polygon in the MultiPolygon. A multi-polygon is an array of polygons,
        // where each polygon is an array of points, where each point is an array of two numbers.
        // The first polygon defines the outer boundary of the feature, and the rest are holes in the feature.
        // Docs: https://geojson.org/geojson-spec.html#polygon (and) https://geojson.org/geojson-spec.html#multipolygon
        for (let subFeatureIndex in japanData.features[featureIndex].geometry.coordinates) {
            let polygon = japanData.features[featureIndex].geometry.coordinates[subFeatureIndex][0];


            // Move to the first point
            ctx.beginPath();
            let firstPoint = convertToCanvasCoords(polygon[0][0], polygon[0][1], bbox);
            ctx.moveTo(firstPoint[0], firstPoint[1]);

            // Draw lines to the rest of the points
            for (let p of polygon) {
                let point = convertToCanvasCoords(p[0], p[1], bbox);
                ctx.lineTo(point[0], point[1]);
            }
            ctx.stroke()
        }
    }
}