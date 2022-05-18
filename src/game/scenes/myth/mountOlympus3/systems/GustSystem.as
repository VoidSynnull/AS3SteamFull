package game.scenes.myth.mountOlympus3.systems
{	
	import flash.display.MovieClip;
	
	import ash.core.Engine;
	import ash.core.NodeList;
	
	import game.scenes.myth.mountOlympus3.bossStates.ZeusState;
	import game.scenes.myth.mountOlympus3.components.Gust;
	import game.scenes.myth.mountOlympus3.nodes.CloudCharacterStateNode;
	import game.scenes.myth.mountOlympus3.nodes.GustNode;
	import game.scenes.myth.mountOlympus3.nodes.ZeusStateNode;
	import game.scenes.myth.mountOlympus3.playerStates.CloudHurt;
	import game.systems.GameSystem;
	import game.util.GeomUtils;
	
	public class GustSystem extends GameSystem
	{
		// audio actions
		private static const EFFECTS:String = 	"effects";
		private static const HIT:String =		"hit";
		private static const SPAWN:String = 	"spawn";
		
		// global variables
		private var pointCount:Number = 0;
		private var wait:Number = 0;
		private var lineColor:uint = 0xCBC998;
		public var lineAlpha:Number = 0.20;
		
		// global nodes
		private var _playerNode:CloudCharacterStateNode;
		private var _zeusNode:ZeusStateNode;
		
		public function GustSystem()
		{
			super( GustNode, updateNode );
			// TODO :: this is doing a draw each frame, probably want tolimit frame rate to a max
			// Though it is also doing a hit test...
		}
		
		override public function addToEngine( systemManager:Engine ):void
		{
			var playerNode:NodeList = systemManager.getNodeList( CloudCharacterStateNode );
			var zeusNode:NodeList = systemManager.getNodeList( ZeusStateNode );
			
			_playerNode = playerNode.head as CloudCharacterStateNode;
			_zeusNode = zeusNode.head as ZeusStateNode;
			
			super.addToEngine( systemManager );
		}
		
		private function updateNode( node:GustNode, time:Number ):void
		{
			var gust:Gust = node.gust;
			
			switch( node.gust.state )
			{
				case Gust.SPAWN:
					node.display.visible = true;
					node.spatial.x = _zeusNode.spatial.x;
					node.spatial.y = _zeusNode.spatial.y;
					gust.rotation = GeomUtils.degreeToRadian( node.spatial.rotation = GeomUtils.degreesBetween( _playerNode.spatial.x, _playerNode.spatial.y, _zeusNode.spatial.x, _zeusNode.spatial.y ));
					gust.t = 30;
					gust.curID = 0;
					gust.vx = 20;
					gust.stx = 0;
					gust.active = true;	
					makeWhirl( node );	
					node.audio.playCurrentAction( SPAWN );
					gust.state = Gust.BLOW;
					break;
				
				case Gust.BLOW:
					updateGustDisplay( node );
					checkForHit( node );
					break;
				
				case Gust.OFF:
					break;
				
				case Gust.END:
					break;
			}
		}
		
		private function checkForHit( node:GustNode ):void 
		{
			if( _playerNode.fsmControl.state.type != CloudHurt.TYPE && testHit( node ))
			{	
				node.audio.stopAll( EFFECTS );
				node.audio.playCurrentAction( HIT );

				_playerNode.hazardCollider.isHit = true;
				_playerNode.hazardCollider.coolDown = 1;
				_playerNode.hazardCollider.interval = .1;
				_playerNode.motion.acceleration.x = node.gust.vx * Math.cos( node.gust.rotation ) * 300;
				_playerNode.motion.acceleration.y = node.gust.vx * Math.sin( node.gust.rotation ) * 300;
				_playerNode.fsmControl.setState( CloudHurt.TYPE );
			}
		}
		
		private function updateGustDisplay( node:GustNode ):void 
		{
			var gust:Gust = node.gust;
			gust.stx += gust.vx;			
			if( gust.t-- <= 0 ) 
			{
				if( gust.whirls.length == 0 ) 
				{
					node.display.visible = false;
					node.gust.state = Gust.OFF;
					node.sleep.sleeping = true;
					ZeusState(_zeusNode.fsmControl.state).moveToNext();
					return;
				}
			} 
			
			else if( gust.t % 6 == 0 && gust.whirls.length < 8 )
			{
				makeWhirl( node );
			}			
			
			var w:Object;
			
			for( var i:Number = gust.whirls.length-1; i >= 0; i--) 
			{				
				w = gust.whirls[ i ];				
				w.alph -= 2;
				if( w.alph < 20 ) 
				{
					//delete w;
					gust.whirls.splice( i,1 );
				}				
				if( w.mode == Gust.SINE ) 
				{					
					if( w.t < w.maxT ) 
					{
						doSine( node, w );
					} 
					else 
					{						
						if( Math.random() < 0.5 ) 
						{
							w.mode = Gust.SPIRAL;
							var dy:Number = Math.cos( w.t );		// Derivative of sine.
							w.t = Math.atan2( dy, gust.vx );
							if( dy < 0 ) 
							{
								w.dt = -0.3;
							} else 
							{
								w.dt = 0.3;
							}
						} 
						else 
						{
							w.maxT += Gust.duration;
						}						
					}
				} 
				else 
				{
					doSpiral( w );
				}				
			}			
			doDraw( node );			
		}
		
		public function doDraw( node:GustNode ):void 
		{
			var gust:Gust = node.gust;
			var clip:MovieClip = node.display.displayObject as MovieClip;
			clip.graphics.clear();			
			var w:Object;
			var pts:Array;
			var pt:Object;
			var prev:Object;			
			for( var i:Number = gust.whirls.length-1; i >= 0; i-- ) {				
				w = gust.whirls[ i ];
				pts = w.pts;				
				prev = pts[ 0 ];
				clip.graphics.lineStyle( 1.5, 0xFFFFFF, w.alph );
				clip.graphics.moveTo( prev.x, prev.y );
				for( var j:Number = 1; j < pts.length; j++ ) 
				{					
					pt = pts[ j ];
					clip.graphics.curveTo( prev.x, prev.y, ( pt.x + prev.x ) / 2, ( pt.y + prev.y ) / 2 );					
					prev = pt;					
				}				
			}			
		}
		
		private function doSine( node:GustNode, w:Object ):void 
		{			
			var gust:Gust = node.gust;
			var clip:MovieClip = node.display.displayObject as MovieClip;
			var pts:Array = w.pts;			
			if( pts.length >= 20 ) 
			{
				pts.shift();		// Remove oldest point.
			}			
			var prev:Object = pts[ pts.length - 1 ];			
			w.t += 0.5;			
			pts.push({ x : ( prev.x + gust.vx ), y : w.y +( w.A * Math.sin( w.t ))});			
		}
		
		private function doSpiral( w:Object ):void 
		{			
			var pts:Array = w.pts;			
			if ( pts.length >= 60 ) 
			{
				pts.shift();		// Remove oldest point.
			}			
			var prev:Object = pts[ pts.length - 1 ];
			w.t += w.dt;			
			w.A *= 0.96;
			pts.push({ x : ( prev.x + w.A * Math.cos( w.t )), y : prev.y + ( w.A * Math.sin( w.t ))});			
		}
		
		public function makeWhirl( node:GustNode ):void 
		{			
			var gust:Gust = node.gust;
			var clip:MovieClip = node.display.displayObject as MovieClip;
			var w:Object = new Object();
			w.A = 6 + 2 * Math.random();				// Whirl amplitude.			
			w.t = 2 * Math.PI * Math.random();				// Whirl timer.
			w.maxT = ( 1.5 + 2 * Math.random()) * Math.PI;
			w.alph = 100;
			w.mode = Gust.SINE;
			w.x = gust.stx - 20 + 40 * Math.random();
			w.y = -50 + 100*  Math.random();
			var pt:Object = { x : w.x + 4, y : w.y + w.A * Math.sin( w.t )};
			w.pts = [ pt ];
			gust.whirls.push( w );
		} 
		
		// Test if player intersects the gust of wind.
		public function testHit( node:GustNode ):Boolean 
		{
			var gust:Gust = node.gust;
			var clip:MovieClip = node.display.displayObject as MovieClip;
			// vector in the direction of the gust.
			var a:Number = ( gust.rotation );
			var dx:Number = Math.cos( a );
			var dy:Number = Math.sin( a );
			var x:Number = _playerNode.spatial.x - node.spatial.x;
			var y:Number = _playerNode.spatial.y - node.spatial.y;
			// dist check the gust vector against player
			if(x * x + y * y > gust.stx * gust.stx ) 
			{
				// Gust has not yet reached the movie.
				return false;
			}
			var dot:Number = x * dx + y * dy;
			// Distance to the line of the gust.
			x -= dot * dx;
			y -= dot * dy;
			if ( x * x + y * y < 4000 ) 
			{
				return true;
			}
			return false;
		}
	}
}