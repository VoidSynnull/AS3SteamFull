package game.scenes.mocktropica.mockLoadingScreen.systems
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	
	import game.scenes.mocktropica.mockLoadingScreen.components.PixelCollapseComponent;
	import game.scenes.mocktropica.mockLoadingScreen.nodes.PixelCollapseNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	
	public class PixelCollapseSystem extends GameSystem
	{
		public function PixelCollapseSystem()
		{
			super( PixelCollapseNode, updateNode );
			super._defaultPriority = SystemPriorities.move;
		}
		
		// Currently ignoring time as this is just a visual effect
		private function updateNode( node:PixelCollapseNode, time:Number):void
		{
			var clip:Sprite = node.display.displayObject as Sprite;
			var pc:PixelCollapseComponent = node.pixelCollapseComponent;
			
			for (var n:uint=0; n<5; n++) {
				addPixel(node, clip);
			}
			
			for (var i:uint=0; i<pc.pixels.length; i++) {
				var curPixel:MovieClip = pc.pixels[i];
				curPixel.vy += pc.gravity;
				curPixel.x += curPixel.vx;
				curPixel.y += curPixel.vy;
				//curPixel.rotation += curPixel.vr;
				if (curPixel.y > pc.gameHeight) {
					pc.pixels.splice(i, 1);
					clip.removeChild(curPixel);
				}
			}
		}
		
		private function addPixel(node:PixelCollapseNode, clip:Sprite):void
		{
			var pc:PixelCollapseComponent = node.pixelCollapseComponent;
			
			if (pc.points.length <= 0) {
				return;
			}
			
			var index:uint = Math.floor(Math.random()*pc.points.length);
			var px:Number = pc.pixelSize*pc.points[index].x;
			var py:Number = pc.pixelSize*pc.points[index].y;
			pc.points.splice(index, 1);
			
			var hole:Sprite = new Sprite();
			hole.x = px;
			hole.y = py;
			hole.graphics.beginFill(0x000000, 1);
			hole.graphics.drawRect(0, 0, pc.pixelSize, pc.pixelSize);
			hole.graphics.endFill();
			clip.addChild(hole);
			
			var pixel:MovieClip = new MovieClip();
			pixel.x = px;
			pixel.y = py;
			pixel.vx = Math.random()*6 - 3;
			pixel.vy = -Math.random()*3;
			//pixel.vr = Math.random()*4 - 2;
			pixel.graphics.lineStyle(1, 0x000000);
			pixel.graphics.beginFill(0x2899FF, 1);
			pixel.graphics.drawRect(0, 0, pc.pixelSize, pc.pixelSize);
			pixel.graphics.endFill();
			pc.pixels.push(pixel);
			clip.addChild(pixel);
		}
	}
}

//reference from prototype
/*
var pixelSize:uint = 20;
var gameWidth:uint = 960;
var gameHeight:uint = 640;
var pixels:Array = new Array();
var gravity:Number = 1.5;
var points:Array = new Array();
var cols:uint = Math.ceil(gameWidth/pixelSize);
var rows:uint = Math.ceil(gameHeight/pixelSize);
var col:uint = 0;
var row:uint = 0;

for (var i:uint=0; i<cols*rows; i++) {
	points.push(new Point(col, row));
	col ++;
	if (col >= cols) {
		row ++;
		col = 0;
	}
}

addEventListener("enterFrame", update);

function update(e:Event):void {
	for (var i:uint=0; i<6; i++) {
		addPixel();
	}
	movePixels();
}

function addPixel():void {
	if (points.length <= 0) {
		return;
	}
	
	var index:uint = Math.floor(Math.random()*points.length);
	var px:Number = pixelSize*points[index].x + pixelSize/2;
	var py:Number = pixelSize*points[index].y + pixelSize/2;
	points.splice(index, 1);
	
	var hole = new Hole();
	hole.x = px;
	hole.y = py;
	addChild(hole);
	
	var pixel = new Pixel();
	pixel.x = px;
	pixel.y = py;
	pixel.vx = Math.random()*8 - 4;
	pixel.vy = -Math.random()*4;
	//pixel.vr = Math.random()*4 - 2;
	pixels.push(pixel);
	addChild(pixel);
}

function movePixels():void {
	for (var i:uint=0; i<pixels.length; i++) {
		var curPixel = pixels[i];
		curPixel.vy += gravity;
		curPixel.x += curPixel.vx;
		curPixel.y += curPixel.vy;
		//curPixel.rotation += curPixel.vr;
		if (curPixel.y > 640) {
			pixels.splice(i, 1);
			removeChild(curPixel);
		}
	}
}
*/