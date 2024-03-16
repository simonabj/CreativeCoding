// Her legger vi til en funksjon til String-objekter som gjør at vi kan gjøre en string stor forbokstav.
String.prototype.capitalize = function() {
    return this.charAt(0).toUpperCase() + this.slice(1);
}

// I have uploaded the GeoJSON file describing the first-level administrative divisions of Japan to my GitHub repository.
// The following code fetches the data from the URL and stores it in the japanData variable.
const dataURL = "https://raw.githubusercontent.com/simonabj/CreativeCoding/main/JapanGeographyGame/First-level_Administrative_Divisions_2015.json"
const dataRequest = new XMLHttpRequest(); // Start by creating a new XMLHttpRequest object
dataRequest.open('GET', dataURL, false);  // Then tell it to fetch the data from the URL while being synchronous
dataRequest.send(null);
let japanData = JSON.parse(dataRequest.responseText); // When the data is received, parse it to JSON

// Så laster vi inn data om prefekturene. Dette er en annen fil som også ligger på GitHuben min.
// Dette er data som inneholder informasjon om hvilke prefekturer som grenser til hverandre, navn i kanji, forkortet kanji,
// kana samt hvilke feature i GeoJSON-filen som representerer prefekturen.
const prefectureDataURL = "https://raw.githubusercontent.com/simonabj/CreativeCoding/main/JapanGeographyGame/japan_prefectures.json";
const prefectureDataRequest = new XMLHttpRequest();
prefectureDataRequest.open('GET', prefectureDataURL, false);
prefectureDataRequest.send(null);
let prefectureData = JSON.parse(prefectureDataRequest.responseText).prefectures;

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
const restartBtnEl = document.getElementById('restartBtn');
const startTextEl = document.getElementById('startText');
const endTextEl = document.getElementById('endText');

const resolution = { x: 900, y: 900 };
canvasEl.width = resolution.x;
canvasEl.height = resolution.y;
let canvas_aspect = resolution.x / resolution.y;

let prefectureMap = createPrefectureMap(); // Liste som mapper prefekturnavn til index i PrefectureData filen
let prefectureIds = createPrefectureIDMap(); // Liste som mapper prefekturID til index i PrefectureData filen
let prefecturesToDraw = [];

/*
 * ====================================================================================================
 *
 *                                           GAME VARIABLES
 * 
 * ====================================================================================================
*/

// PrefecturePathLength er antall prefekturer koblet sammen for 1 runde. Jo færre prefekturer, jo
// enklere blir runden. Denne skal kunne styres av brukeren.
let PrefecturePathLength = 3;   

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

// startPrefecture er en variabel som holder på indexen til prefekturen som spilleren starter fra. 
// Denne er tilfeldig valgt ved starten av hver runde.
let startPrefecture = -1; 

// endPrefecture er en variabel som holder på indexen til prefekturen som er målet for spilleren.
// Denne er tilfeldig valgt blandt de prefekturene som er PrefecturePathLength unna startPrefecture.
let endPrefecture = -1;

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

// Lag en liste over alle prefekturer som spilleren kan velge fra. Disse vises i en dropdown-meny
// som er tilgjenglig for spilleren dersom de velger en enkel modus.
for (let prefectureName in prefectureMap) {
    let new_option = document.createElement('option');
    new_option.value = prefectureMap[prefectureName];
    new_option.textContent = prefectureName.capitalize();
    prefecturePickerEl.appendChild(new_option);
}

function startRunde() {
    // Velg en tilfeldig prefektur å starte fra
    startPrefecture = randomFromList(Object.keys(prefectureIds));
    endPrefecture = randomFromList(getNStepsAway(startPrefecture, PrefecturePathLength+1));

    startTextEl.textContent = find("id", startPrefecture).en.capitalize();
    endTextEl.textContent = find("id", endPrefecture).en.capitalize();

    addPrefecture(prefectureIds[startPrefecture]);
    addPrefecture(prefectureIds[endPrefecture]);
    drawPrefectures();
}

function restartRunde() {
    prefecturesToDraw = [];

    startRunde();
}

startRunde();

/*
 * ====================================================================================================
 *
 *                                        EVENT LISTENERS
 * 
 * ====================================================================================================
*/

addButtonEl.addEventListener('click', () => {
    let selectedPrefectureIndex = Number(prefecturePickerEl.value);
    // Only add the feature if it's not already in the list
    if (!prefecturesToDraw.includes(selectedPrefectureIndex)) {
        createPrefectureListItem(selectedPrefectureIndex)
        addPrefecture(selectedPrefectureIndex);
        drawPrefectures();
    }
});

restartBtnEl.addEventListener('click', restartRunde);


/* 
 * ====================================================================================================
 *
 *                                         HELPER FUNCTIONS 
 * 
 * ==================================================================================================== 
*/

// Hjelpe funksjon for å finne en prefektur basert på en egenskap og en verdi.
// Eksempel: find("en", "saitama") eller find("short", "東京")
function find(term, value) {
    return prefectureData.filter(prefecture => prefecture[term] == value)[0];
}

// Denne funksjonen lager et nytt listeelement i prefectureListEl og legger til en eventlistener som fjerner den 
// når den blir klikket på.
function createPrefectureListItem(prefectureIndex) {
    let listItem = document.createElement('li');
    listItem.textContent = prefectureData[prefectureIndex].en.capitalize();
    listItem.classList.add('prefListItem');
    listItem.addEventListener('click', () => {
        listItem.parentNode.removeChild(listItem);
        removePrefecture(prefectureIndex);
        drawPrefectures();
    });

    prefectureListEl.appendChild(listItem);
}

// Funksjon som returnerer et tilfeldig element fra en liste
function randomFromList(list) {
    return list[Math.floor(Math.random() * list.length)];
}

// Lag en liste med alle prefekturer som er akuratt N antall steg unna start. 
// Siden grensene er en syklisk graf, må vi også ta hensyn til at vi ikke går tilbake i ring. 
// Dette gjøres ved et bredde-først-søk. https://en.wikipedia.org/wiki/Breadth-first_search
// Merk, start er id'en til en prefektur som definert i PrefectureData filen.
function getNStepsAway(start_id, N) {
    let queue = [start_id];
    let visited = new Set([start_id]);
    let distance = {};
    distance[start_id] = 0;

    while (queue.length > 0) {
        let current = queue.shift();
    
        // Siden vi gjør bredde-først-søk, vil vi alltid finne den korteste veien først.
        // Altså kan vi avslutte søket når vi finner en node som er lenger enn N steg unna start.
        if (distance[current] > N) { 
            break;
        }

        for (let neighbor of find("id", current).neighbor) {
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

// Siden punktene er i geografiske (lengde- og breddegrad) koordinater, må vi konvertere disse til canvas-koordinater.
// Vi antar at japan er såpass lite at en flat projeksjon på canvas holder, så vi gjør kun en enkel lineær transformasjon
// for å konvertere fra geografiske koordinater til canvas-koordinater.
function convertToCanvasCoords(long, lat, bbox = japanData.bbox) {
    let width = canvasEl.width;
    let height = canvasEl.height;

    // Trekk fra minimumet for x og y for å få en verdi mellom 0 og maksimumet
    // Del så på maksimumet (med minimumet også trekt fra) for å få en verdi mellom 0 og 1
    // Til slutt, multipliser med bredde/høyde av canvas for å få en verdi mellom 0 og bredde/høyde
    let x = (long - bbox[0]) / (bbox[2] - bbox[0]) * width;
    let y = height - (lat - bbox[1]) / (bbox[3] - bbox[1]) * height;
    return [x, y];
}

// Lag en bounding-box for gitt feature i GeoJSON fila. Disse bestemmer hjørnene i et rektangel som garanterer og inneholde
// alle punktene i et polygon.
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

// Siden GeoJSON beskriver MultiPolygons, kan vi ha flere polygoner i en feature. Denne funksjonen returnerer
// hvor mange polygoner det er i en feature
function numSubFeatures(featureIndex) {
    return japanData.features[featureIndex].geometry.coordinates.length;
}

// SurroundingBBox kombinerer alle bounding boxes til en stor bounding box som inneholder alle punktene i alle polygonene.
function surroundingBBox() {
    let [minX, minY, maxX, maxY] = [Infinity, Infinity, -Infinity, -Infinity]; // Same as above, but shorter
    for (let prefectureIndex of prefecturesToDraw) {
        let bbox = getFeatureBBox(prefectureData[prefectureIndex].featureIndex);
        minX = Math.min(minX, bbox[0]);
        minY = Math.min(minY, bbox[1]);
        maxX = Math.max(maxX, bbox[2]);
        maxY = Math.max(maxY, bbox[3]);
    }
    return [minX, minY, maxX, maxY];
}

// Siden vi ønsker å opprettholde forholdet mellom bredde og høyde av det vi tegner, så må vi strekke bounding boxen til å
// passe Canvas. Dette gjøres ved en enkel lineær transformasjon.
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

// Konstruer et map over alle prefecturer og deres index i PrefectureData filen
function createPrefectureMap() {
    let prefectureMap = {}
    for (let i = 0; i < prefectureData.length; i++) {
        let prefecture = prefectureData[i];
        let name = prefecture.en;
        prefectureMap[name] = i;
    }
    return prefectureMap;
}

// Identisk til createPrefectureMap over, men denne binder ID'en til prefekturen til indexen i PrefectureData filen.
// Dette brukes for å raskt slå opp prefectureIndex fra en ID.
function createPrefectureIDMap() {
    let prefectureMap = {}
    for (let i = 0; i < prefectureData.length; i++) {
        let prefecture = prefectureData[i];
        let name = prefecture.id;
        prefectureMap[name] = i;
    }
    return prefectureMap;
}

// drawFeature funksjonen tar en index av en prefecture og legger til den 
// til lista over prefecturesToDraw
function addPrefecture(prefectureIndex) {
    if (prefecturesToDraw.includes(prefectureIndex)) {
        console.log("Prefecture already in list. Skipping.")
        return;
    }

    prefectureName = prefectureData[prefectureIndex].en;
    console.log(`Adding ${prefectureName} to the list of prefectures to draw`);
    prefecturesToDraw.push(prefectureIndex);
}

// Samme som over, men fjerner en feature fra lista
function removePrefecture(featureIndex) {
    prefecturesToDraw = prefecturesToDraw.filter((index) => index !== featureIndex);
    console.log(`Removing ${japanData.features[featureIndex].properties.name_1} from the list of prefectures to draw`);
}

// drawPrefectures funksjonen tegner alle prefekturer som er i lista over prefecturesToDraw.
// Den burde kun kjøres når lista over prefecturesToDraw endres.
function drawPrefectures() {
    // Clear the canvas
    ctx.clearRect(0, 0, canvasEl.width, canvasEl.height);

    // Get the bounding box of all the prefectures to draw
    let bbox = surroundingBBox();
    let bbox_aspect = (bbox[2] - bbox[0]) / (bbox[3] - bbox[1]);
    console.log("Bounding box aspect ratio: " + bbox_aspect);
    console.log("Canvas aspect ratio: " + canvas_aspect);

    bbox = normalizeBBox(bbox);
    bbox_aspect = (bbox[2] - bbox[0]) / (bbox[3] - bbox[1]);

    // If the bounding box is wider than the canvas, we need to scale the y-coordinates of the bbox
    // bbox = bbox_aspect > canvas_aspect ? [bbox[0], bbox[1], bbox[2], bbox[1] + (bbox[2] - bbox[0]) / canvas_aspect] : bbox;

    // For every feature in the prefecturesToDraw array, draw it on the canvas
    for (let prefectureIndex of prefecturesToDraw) {
        // Hent ut indexen til featuren i GeoJSON filen som representerer prefekturen
        let featureIndex = prefectureData[prefectureIndex].featureIndex;

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