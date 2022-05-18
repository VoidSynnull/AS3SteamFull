package game.scenes.custom.trackBuilderSystems
{
	
	import flash.display.MovieClip;
	
	import ash.core.Node;
	
	import game.scenes.custom.TrackBuilderPopup;
	import game.systems.GameSystem;
	
	public class TrackBuilderSystem extends GameSystem
	{
		private var _popup:TrackBuilderPopup;
		private var _runClip:MovieClip;
		
		private var _currentPieceIndex:int;
		private var _trackPieces:Array;
		
		private var _pieceWidth:int;
		private var _gapAdjustment:Number;
		
		private var _pieceList:Array;
		private var _guidePieces:Array;
		
		private var _currentGuide:MovieClip;
		
		private var _carSpeed:Number;
		private var _carStartingIntervals:Number;
		
		private var _previousGuideLocationX:Number;
		private var _previousGuideLocationY:Number;
		
		private var _runPhase:Number;
		
		private var _elapsedTime:Number;
		private var _animationRate:Number;
		
		//private var _game:TargetShootingGamePower;
		public function TrackBuilderSystem(popup:TrackBuilderPopup, runClip:MovieClip, pieceSelections:Array):void
		{
			_popup = popup;
			_runClip = runClip;
			
			_runClip.mc_clouds.gotoAndPlay(1);
			
			_currentPieceIndex = 1;
			_trackPieces = new Array(_runClip.mc_trackPiece1, _runClip.mc_trackPiece2, _runClip.mc_trackPiece3);
			_pieceWidth = 400;
			_gapAdjustment = 0;
			_pieceList = new Array(1, pieceSelections[0], 1, pieceSelections[1], 1, pieceSelections[2], 1, pieceSelections[3], 1, pieceSelections[4], 1, pieceSelections[5], 1, 1, 1);
			
			_runClip.mc_trackPiece1.gotoAndStop(_pieceList.splice(0, 1))
			_runClip.mc_trackPiece2.gotoAndStop(_pieceList.splice(0, 1));
			_runClip.mc_trackPiece3.gotoAndStop(_pieceList.splice(0, 1));
			
			_guidePieces = new Array(_runClip.mc_guidePiece1, _runClip.mc_guidePiece2, _runClip.mc_guidePiece3, _runClip.mc_guidePiece4, _runClip.mc_guidePiece5, _runClip.mc_guidePiece6);
			
			for ( var i:int = 0; i < _guidePieces.length; i ++ )
				_guidePieces[i].gotoAndStop(1);
			
			_currentGuide = _guidePieces[_trackPieces[1].currentFrame - 1];
			_guidePieces[_trackPieces[1].currentFrame - 1].gotoAndStop(1);
			
			_currentGuide.x = _trackPieces[1].x;
			
			_carSpeed = 20;
			_carStartingIntervals = 75;
			
			_runClip.mc_car.x = _currentGuide.x + _currentGuide.coasterCar.x - (_carStartingIntervals * _carSpeed);
			_runClip.mc_car.y = _currentGuide.y + _currentGuide.coasterCar.y;
			
			_previousGuideLocationX = _currentGuide.coasterCar.x;
			_previousGuideLocationY = _currentGuide.coasterCar.y;
			
			_runPhase = 1;
			_elapsedTime = 0;
			_animationRate = 1;
			
			_runClip.mc_background1.gotoAndStop(1);
			_runClip.mc_background2.gotoAndStop(1);
			_runClip.mc_background3.gotoAndStop(1);
			
			super( Node, updateNode, nodeAdded, nodeRemoved );			
		}
		
		private function updateNode( node:Node, etime:Number ):void
		{
			_elapsedTime += etime;
			
			if ( _elapsedTime < _animationRate )
				return;
			
			_elapsedTime -= _animationRate;
			
			switch ( _runPhase )
			{
				case 1:
					runToTrack();
					break;
				case 2:
					runTrack();
					break;
				case 3:
					exitRun();
					break;
			}
			
			_runClip.mc_background1.gotoAndStop(_runClip.mc_background1.currentFrame + 1);
			_runClip.mc_background2.gotoAndStop(_runClip.mc_background1.currentFrame + 1);
			_runClip.mc_background3.gotoAndStop(_runClip.mc_background1.currentFrame + 1);
		}
		
		private function runToTrack():void
		{	
			_runClip.mc_car.x += _carSpeed;
			_carStartingIntervals --;
			if ( _carStartingIntervals == 0 )
				_runPhase ++;	
		}
		
		private function runTrack():void
		{
			_runClip.mc_car.rotation = _currentGuide.coasterCar.rotation;
			
			var newGuideLocationX:Number = _currentGuide.coasterCar.x;
			var newGuideLocationY:Number = _currentGuide.coasterCar.y;
			var xDisplacement:Number = newGuideLocationX - _previousGuideLocationX; 
			var yDisplacement:Number = newGuideLocationY - _previousGuideLocationY; 
			
			moveHorizontally(xDisplacement);
			_runClip.mc_car.y += yDisplacement;	
			
			_previousGuideLocationX = newGuideLocationX;
			_previousGuideLocationY = newGuideLocationY;
			
			if ( _currentGuide.currentFrame == _currentGuide.totalFrames )
			{
				_currentGuide.gotoAndStop(1);
				
				_currentPieceIndex ++;
				if ( _currentPieceIndex == _trackPieces.length )
					_currentPieceIndex = 0;
				
				_currentGuide = _guidePieces[_trackPieces[_currentPieceIndex].currentFrame - 1];
				_currentGuide.x = _trackPieces[_currentPieceIndex].x;
				
				_previousGuideLocationX = _previousGuideLocationY = 0;
			}
			
			if ( _pieceList.length == 0 )
				_runPhase ++;
			else
				_currentGuide.gotoAndStop(_currentGuide.currentFrame + 1);
		}
		
		private function moveHorizontally(displacement:Number):void
		{	
			_runClip.mc_foreground1.x -= 1.1 * displacement;
			_runClip.mc_foreground2.x -= 1.1 * displacement;
			
			if ( _runClip.mc_foreground1.x < -(_runClip.mc_foreground1.width + 25) )
				_runClip.mc_foreground1.x = 650;
			if ( _runClip.mc_foreground2.x < -(_runClip.mc_foreground2.width + 25) )
				_runClip.mc_foreground2.x = 650;
			
			_runClip.mc_trackPiece1.x -= displacement;
			_runClip.mc_trackPiece2.x -= displacement;
			_runClip.mc_trackPiece3.x -= displacement;
			_currentGuide.x = _trackPieces[_currentPieceIndex].x;
			
			if ( _runClip.mc_trackPiece1.x < -(_pieceWidth + 100) )
			{
				_runClip.mc_trackPiece1.gotoAndStop(_pieceList.splice(0, 1));
				_runClip.mc_trackPiece1.x = _runClip.mc_trackPiece3.x + _pieceWidth - _gapAdjustment;
			}
			else if ( _runClip.mc_trackPiece2.x < -(_pieceWidth + 100) )
			{
				_runClip.mc_trackPiece2.gotoAndStop(_pieceList.splice(0, 1));
				_runClip.mc_trackPiece2.x = _runClip.mc_trackPiece1.x + _pieceWidth - _gapAdjustment;
			}
			else if ( _runClip.mc_trackPiece3.x < -(_pieceWidth + 100) )
			{
				_runClip.mc_trackPiece3.gotoAndStop(_pieceList.splice(0, 1));
				_runClip.mc_trackPiece3.x = _runClip.mc_trackPiece2.x + _pieceWidth - _gapAdjustment;
			}
			
			_runClip.mc_stands1.x -= displacement;
			_runClip.mc_stands2.x -= displacement;
			_runClip.mc_stands3.x -= displacement;
			
			if ( _runClip.mc_stands1.x < -600 )
				_runClip.mc_stands1.x += 1500;
			if ( _runClip.mc_stands2.x < -600 )
				_runClip.mc_stands2.x += 1500;
			if ( _runClip.mc_stands3.x < -600 )
				_runClip.mc_stands3.x += 1500;
			
			_runClip.mc_background1.x -= 0.1 * displacement;
			_runClip.mc_background2.x -= 0.1 * displacement;
			_runClip.mc_background3.x -= 0.1 * displacement;
			
			if ( _runClip.mc_background1.x < -(_runClip.mc_background1.width + 100) )
				_runClip.mc_background1.x += 1200 - _gapAdjustment;
			if ( _runClip.mc_background2.x < -(_runClip.mc_background2.width + 100) )
				_runClip.mc_background2.x += 1200 - _gapAdjustment;
			if ( _runClip.mc_background3.x < -(_runClip.mc_background3.width + 100) )
				_runClip.mc_background3.x += 1200 - _gapAdjustment;
		}
		
		private function exitRun():void
		{
			_runClip.mc_car.x += _carSpeed;
			if ( _runClip.mc_car.x > 700 )
				_popup.endRun();
		}		
		
		private function nodeAdded(node:Node):void
		{
			
		}
		
		private function nodeRemoved(node:Node):void
		{
			
		}
	}
}