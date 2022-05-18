package game.particles.emitter.specialAbility 
{
	import flash.display.MovieClip;
	import flash.display.Sprite;
	import flash.filters.BlurFilter;
	import flash.filters.GlowFilter;
	import flash.geom.Point;
	import flash.utils.clearTimeout;
	import flash.utils.setTimeout;
	
	public class ElectricBall extends MovieClip
	{
		private var iMaxDepth : int = 3;
		public var iMaxRespawnTime : Number = 1200;
		private var iMaxBranches : int = 3;
		public var iMaxLineW : int = 4;
		public var iMaxLineLen : int = 35;
		private var aBranches : Array = new Array();
		private var aEndPts : Array = new Array();
		private var uT : uint;
		private var iDepth : int;
		private var linesHolderMC : MovieClip;
		private var centerMC : MovieClip;
		private var maskMC : MovieClip;
		private var sType : String = "normal";
		private var originPt : Point;
		
		public function ElectricBall(iCurDepth:Number, regPt:Point, sT:String):void{
			if(iCurDepth < iMaxDepth){
				sType = sT;
				originPt = regPt;
				iDepth = iCurDepth;
				spawnLines(regPt);
			}
		}
		
		private function spawnLines(regPt:Point):void{
			destroy();
			linesHolderMC = new MovieClip();
			addChild(linesHolderMC);
			var iNumLines : Number =  Math.ceil(Math.random() * iMaxBranches);
			for(var i : uint = 0; i < iNumLines; i++){
				createLine(i, regPt);
			}
			var iNextSpawnMS : Number = 50 + Math.round(Math.random() * iMaxRespawnTime/(iDepth+1));
			uT = setTimeout(spawnLines, iNextSpawnMS, regPt);
			if(iDepth == 0){
				addCenterBall();
			}
		}
		
		private function addCenterBall():void{
			var sBall : Sprite = new Sprite();
			var circRad : Number = 12 + Math.round(Math.random() * 7);
			var blurDist : Number = 7 + Math.round(Math.random() * 5);
			sBall.graphics.beginFill(0xFFFFFF);
			sBall.graphics.drawCircle(0,0,circRad);
			sBall.graphics.endFill();
			centerMC = new MovieClip();
			centerMC.addChild(sBall);
			centerMC.alpha = 0.4 + Math.random() * 0.6;
			centerMC.filters = [new BlurFilter(blurDist, blurDist, 3)];
			addChild(centerMC);
			//linesHolderMC.filters = [new GlowFilter(0xFFFFFF, 0.2, 3, 3, 5, 3), new GlowFilter(0xFFFFFF, 0.4, 15, 15, 5, 3) ];
			
		}
		
		public function set type(sT:String):void{
			sType = sT;
			spawnLines(originPt);
		}
		
		
		private function createLine(iIndex:int, startPt:Point):void{
			var lineMC : MovieClip = new MovieClip();
			var sLine : Sprite = new Sprite();
			var lineW : Number = iMaxLineW - (iDepth);
			var lineLen : Number = iMaxLineLen / 3 + 2 * iMaxLineLen * (1 - iDepth/iMaxDepth) / 3;
			switch(sType){
				case "horizontal":
					aEndPts[iIndex] = new Point(startPt.x + 2 * lineLen - Math.round(Math.random() * 4 * lineLen), startPt.y + lineLen/2 - Math.round(Math.random() * lineLen));
					break;
				case "vertical":
					aEndPts[iIndex] = new Point(startPt.x + lineLen/2 - Math.round(Math.random() * lineLen), startPt.y + 2 * lineLen - Math.round(Math.random() * 4 * lineLen));	
					break;
				case "normal":
					aEndPts[iIndex] = new Point(startPt.x + lineLen - Math.round(Math.random() * 2 * lineLen), startPt.y + lineLen - Math.round(Math.random() * 2 * lineLen));	
					break;
			}
			sLine.graphics.lineStyle(lineW,0xFFFFFF);
			sLine.graphics.moveTo(startPt.x, startPt.y);
			sLine.graphics.lineTo(aEndPts[iIndex].x, aEndPts[iIndex].y);
			lineMC.addChild(sLine);
			aBranches[iIndex] = lineMC;
			linesHolderMC.addChild(aBranches[iIndex]);
			if(iDepth < iMaxDepth-1){
				var lineBall : ElectricBall = new ElectricBall(iDepth+1, aEndPts[iIndex], sType);
				lineMC.lineBall = lineBall;
				lineMC.addChild(lineBall);
			}
		}
		
		
		
		public function destroy():void{
			clearTimeout(uT);
			for(var i : uint = 0; i < aBranches.length; i++){
				if(aBranches[i].lineBall){
					aBranches[i].lineBall.destroy();
				}
				linesHolderMC.removeChild(aBranches[i]);
				aBranches[i] = null;
			}
			if(centerMC){
				removeChild(centerMC);
				centerMC = null;
			}
			if(linesHolderMC){
				removeChild(linesHolderMC);
				linesHolderMC = null;
			}
			aBranches = new Array();
		}
		
		
	}

}