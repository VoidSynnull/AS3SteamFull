package game.scenes.gameJam.dancingZombie.systems
{
	import flash.display.MovieClip;
	
	import engine.components.Spatial;
	
	import game.scenes.gameJam.dancingZombie.nodes.DiscoTileNode;
	import game.systems.GameSystem;
	import game.systems.SystemPriorities;
	import game.util.ColorUtil;
	import game.util.TweenUtils;

	public class DiscoTileSystem extends GameSystem
	{
		//private var _colors:Vector.<Number> = new <Number>[ 0XB84E9D, 0x6ACBDE, 0xF5EB00, 0x66BC46, 0XED1E24, 0xF8981D, 0x3C59A8, 0X834AD3];
		//private var _colors:Vector.<Number> = new <Number>[ 0XB84E9D, 0x6ACBDE];
		private var _colors:Vector.<Number> = new <Number>[ 0xF8981D, 0x6ACBDE ];
		private const LIT_ALPHA:Number = 1.0;
		private const UNLIT_ALPHA:Number = 0.4;
		private const UNLIT_DECREMENT:Number = 0.01;
		
		private const BOUNCE_SCALE:Number = 0.06;// add to scale on note tick

		private var _litColumn:int = -1;

		private var _colorLastMeasure:Number = 0XFFFFFF;
		
		public function DiscoTileSystem()
		{
			super( DiscoTileNode, updateNode, nodeAdded );
			super._defaultPriority = SystemPriorities.animate;
		}
		
		private function nodeAdded(node:DiscoTileNode):void
		{
			node.discoTile.colorIndex = node.discoTile.colorIndex % _colors.length;
			MovieClip(node.display.displayObject["tileClip"]["colorClip"]).alpha = UNLIT_ALPHA;
		}
		
		private function updateNode(node:DiscoTileNode, time:Number):void
		{
			if( node.beatDriven.beatHit )
			{
				changeColor( node );
			}
			if( node.discoTile.lit )
			{
				decreaseLit(node);
			}
		}

		private function changeColor( node:DiscoTileNode ):void
		{
			var nextColor:Number;
			if( !node.discoTile.ignoreColor )
			{
				node.discoTile.colorIndex++;
				if( node.discoTile.colorIndex >= _colors.length )	{ node.discoTile.colorIndex = 0; } 
				nextColor = _colors[ node.discoTile.colorIndex ];
				//nextColor = _colors[ Math.floor( Math.random() * _colors.length ) ];	//randomized
				
			}
			else
			{
				nextColor = 0XFFFFFF;
			}

			// get colorable tile
			var colorClip:MovieClip = node.display.displayObject["tileClip"]["colorClip"];
			ColorUtil.colorize( colorClip, nextColor);
			// scale up and then down on the beat
			scale:node.spatial.scale += BOUNCE_SCALE;
			TweenUtils.entityTo(node.entity, Spatial, 0.15, {scale:node.spatial.scale - BOUNCE_SCALE});
			/*
			if( colorClip.alpha == 1 )
			{
				colorClip.alpha = UNLIT_ALPHA;
			}
			*/
			
			/*
			node.discoTile.beatMeasure++;
			if( node.discoTile.beatMeasure > node.beatDriven.maxMeasure )
			{
				node.discoTile.beatMeasure = 1;
				colorClip.alpha = LIT_ALPHA;
			}
			else
			{
				colorClip.alpha = UNLIT_ALPHA;
			}
			*/
		}
		
		private function decreaseLit( node:DiscoTileNode ):void
		{
			var colorClip:MovieClip = node.display.displayObject["tileClip"]["colorClip"];
			colorClip.alpha -= UNLIT_DECREMENT;
			if( colorClip.alpha <= UNLIT_ALPHA )
			{
				colorClip.alpha = UNLIT_ALPHA;
				node.discoTile.lit = false;
			}
		}
	}
}