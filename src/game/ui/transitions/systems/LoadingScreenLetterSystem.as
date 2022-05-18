package game.ui.transitions.systems
{
	import flash.display.DisplayObject;
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.Entity;
	
	import engine.components.Spatial;
	
	import game.components.input.Input;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.ui.transitions.components.LoadingScreenLetterComponent;
	import game.ui.transitions.nodes.LoadingScreenLetterNode;
	
	public class LoadingScreenLetterSystem extends GameSystem
	{
		public function LoadingScreenLetterSystem()
		{
			super( LoadingScreenLetterNode, updateNode );
			super._defaultPriority = SystemPriorities.move;
		}
		
		// Currently ignoring time as wave motion based components don't need to make up lost time like standard velocity components that move entities around the screen.
		private function updateNode( node:LoadingScreenLetterNode, time:Number):void
		{
			// TODO : wrb - need to fix cleanup of shared components.
			if(_input == null)
			{
				if( super.group.shellApi.inputEntity )
				{
					_input = super.group.shellApi.inputEntity.get(Input);
				}
				else
				{
					return;
				}
			}
			
			var spatial:Spatial = node.spatial;
			var l:LoadingScreenLetterComponent = node.movingLetterComponent;
			var clip:DisplayObject = node.display.displayObject;
			var input:Input = _input;
			
			l.waveTime -= l.waveSpeed;
			if (l.doWave) {
				l.baseX = l.startX + 0.5*l.waveMag*Math.cos(l.waveTime);
				l.baseY = l.startY + l.waveMag*Math.sin(l.waveTime);
			}
			clip["overlay"].alpha = -Math.sin(l.waveTime);
			l.ax = (l.baseX - spatial.x)*l.k;
			l.ay = (l.baseY - spatial.y)*l.k;
			l.dx = input.target.x - spatial.x;
			l.dy = input.target.y - spatial.y;
			
			l.dist = Math.sqrt(l.dx*l.dx + l.dy*l.dy);
			l.radians = Math.atan2(l.dy, l.dx);
			if (l.dist < l.maxRepelDistance) {
				l.ax -= 0.05*(l.maxRepelDistance - l.dist)*Math.cos(l.radians);
				l.ay -= 0.05*(l.maxRepelDistance - l.dist)*Math.sin(l.radians);
			}
			l.vx += l.ax;
			l.vy += l.ay;
			l.vx *= l.damp;
			l.vy *= l.damp;
			spatial.x += l.vx;
			spatial.y += l.vy;
			spatial.rotation = l.vx;
			if (l.hasExtrusion) {
				var extrusion:MovieClip = clip.parent[clip.name + "Extrusion"];
				extrusion.x = spatial.x;
				extrusion.y = spatial.y;
				extrusion.rotation = spatial.rotation;
			}
			if (l.hasOutline) {
				var outline:MovieClip = clip.parent[clip.name + "Outline"];
				outline.x = spatial.x;
				outline.y = spatial.y;
				outline.rotation = spatial.rotation;
			}
		}
	
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(LoadingScreenLetterNode);
			super.removeFromEngine(systemManager);
		}
		
		private var _input:Input;
	}
}

//reference from prototype
/*
var lettersArray:Array = new Array();
var i:uint;
var waveTime:Number = 0;
var waveSpeed:Number = 0.15;
var waveMag:Number = 5; //wave magnitude
var damp:Number = 0.8;
var k:Number = 0.05; //spring constant
var maxRepelDistance:Number = 100;
var nuletters:uint = 16;
var numSounds:uint = 9;
var soundsArray:Array = new Array();

initSounds();
initLetters();

function initSounds():void {
	for (i=1; i<=numSounds; i++) {
		var soundName:String = "piano" + i + ".mp3";
		var curSound:Sound = new Sound();
		curSound.load(new URLRequest("sound/" + soundName));
		soundsArray.push(curSound);
	}
}

function initLetters():void {
	for (i=1; i<=16; i++) {
		var l = this["l" + i];
		lettersArray.push(l);
		l.waveTimeOffset = i*0.6;
		l.startX = l.x;
		l.startY = l.y;
		l.baseX = l.x;
		l.baseY = l.y;
		l.ax = 0;
		l.ay = 0;
		l.vx = 0;
		l.vy = 0;
		l.dist = 0;
		l.radians = 0;
		l.dx = 0; //distance from mouse
		l.dy = 0;
		l.canPlayNote = true;
	}
	addEventListener("enterFrame", update);
}

function update(e:Event):void {
	waveTime -= waveSpeed;
	for (i=0; i<lettersArray.length; i++) {
		var l = lettersArray[i];
		if (i < 11) {
			l.baseX = l.startX + 0.5*waveMag*Math.cos(waveTime + l.waveTimeOffset);
			l.baseY = l.startY + waveMag*Math.sin(waveTime + l.waveTimeOffset);
		}
		if (l.overlay != undefined) {
			l.overlay.alpha = -Math.sin(waveTime + l.waveTimeOffset);
		}
		l.ax = (l.baseX - l.x)*k;
		l.ay = (l.baseY - l.y)*k;
		l.dx = mouseX - l.x;
		l.dy = mouseY - l.y;
		l.dist = Math.sqrt(l.dx*l.dx + l.dy*l.dy);
		l.radians = Math.atan2(l.dy, l.dx);
		if (l.dist < maxRepelDistance) {
			l.ax -= 0.1*(maxRepelDistance - l.dist)*Math.cos(l.radians);
			l.ay -= 0.1*(maxRepelDistance - l.dist)*Math.sin(l.radians);
			if (l.canPlayNote) {
				playSound(i);
				l.canPlayNote = false;
			}
		}
		else {
			l.canPlayNote = true;
		}
		l.vx += l.ax;
		l.vy += l.ay;
		l.vx *= damp;
		l.vy *= damp;
		l.x += l.vx;
		l.y += l.vy;
		l.rotation = l.vx;
		var extrusion = this[l.name + "Extrusion"];
		var outline = this[l.name + "Outline"];
		if (extrusion != undefined) {
			extrusion.x = l.x;
			extrusion.y = l.y;
			extrusion.rotation = l.rotation;
		}
		if (outline != undefined) {
			outline.x = l.x;
			outline.y = l.y;
			outline.rotation = l.rotation;
		}
	}
}

function playSound(noteNum:uint):void {
	//if (noteNum >= soundsArray.length) {
	//noteNum -= soundsArray.length;
	//}
	noteNum = Math.floor(Math.random()*soundsArray.length);
	soundsArray[noteNum].play();
}
*/
