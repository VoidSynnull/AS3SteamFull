package game.systems.entity
{
	import com.poptropica.AppConfig;
	
	import flash.display.DisplayObjectContainer;
	import flash.display.MovieClip;
	import flash.geom.Rectangle;
	import flash.utils.Dictionary;
	
	import ash.core.Component;
	import ash.core.Engine;
	import ash.core.Entity;
	import ash.core.NodeList;
	import ash.core.System;
	
	import engine.ShellApi;
	import engine.components.Display;
	import engine.components.Spatial;
	import engine.util.Command;
	
	import game.components.entity.Children;
	import game.components.entity.Parent;
	import game.components.entity.State;
	import game.components.entity.character.ColorSet;
	import game.components.entity.character.Profile;
	import game.components.entity.character.part.MetaPart;
	import game.components.entity.character.part.SkinPart;
	import game.components.timeline.Timeline;
	import game.components.timeline.TimelineClip;
	import game.components.timeline.TimelineMaster;
	import game.data.StateData;
	import game.data.character.LookAspectData;
	import game.data.character.LookData;
	import game.data.character.part.ColorAspectData;
	import game.data.character.part.ColorByPartData;
	import game.data.character.part.ColorableData;
	import game.data.character.part.PartMetaData;
	import game.data.character.part.PartMetaDataParser;
	import game.data.character.part.SkinPartId;
	import game.data.character.part.StateByPartData;
	import game.data.display.BitmapWrapper;
	import game.nodes.entity.SkinNode;
	import game.scene.template.ui.CardGroup;
	import game.systems.SystemPriorities;
	import game.util.CharUtils;
	import game.util.ClassUtils;
	import game.util.DataUtils;
	import game.util.DisplayUtils;
	import game.util.EntityUtils;
	import game.util.PlatformUtils;
	import game.util.SkinUtils;
	import game.util.TimelineUtils;
	
	import org.osflash.signals.Signal;
	
	/**
	 * Update part entities with new asset and metadata
	 */
	public class SkinSystem extends System
	{
		public function SkinSystem()
		{
			super._defaultPriority = SystemPriorities.render;
		}
		
		override public function addToEngine( systemsManager : Engine ) : void
		{
			_nodes = systemsManager.getNodeList( SkinNode );
			 
			super.addToEngine( systemsManager );
			_metaDataParser = new PartMetaDataParser();
			
			// Only necessary for debugging, should be commented out otherwise
			errorSignal = new Signal( String );
		}
		
		override public function removeFromEngine(systemManager:Engine):void
		{
			systemManager.releaseNodeList(SkinNode);
			_nodes = null;
		}
		
		override public function update(time:Number):void
		{
			var node:SkinNode;
			for( node = _nodes.head; node; node = node.next )
			{
				updateNode(node, time);
			}
		}
		
		private function updateNode(node:SkinNode, time:Number):void
		{
			var skinPart:SkinPart = node.skinPart;
			var metaPart:MetaPart = node.metaPart;
			var display:Display = node.display;
			
			// If SkinPart values have changed, update changes to Part's metadata
			if ( skinPart._invalidate )
			{
				// NOTE :: set invalidate to false prior to updating value
				skinPart._invalidate = false;
				updateSkinValue( node );
			}

			if( display )
			{
				// If display needs to be refreshed
				if( skinPart.refreshDisplay )
				{
					if( skinPart.isEmpty || ( metaPart.nextData && metaPart.nextData.asset == PartMetaData.NONE ) )
					{
						display.empty();
						display.disposeBitmaps();
					}
					else
					{
						display.visible = !skinPart.hidden;
						if( skinPart.reload )
						{
							loadAsset( node );
							skinPart.reload = false;
						}
					}
					skinPart.refreshDisplay = false;
				}
				
				// If Display's displayObject has changed, apply metadata
				if ( display.invalidate )	//TODO :: if empty is chosen, does this not fire?  That would be a problem
				{
					// clear all entity children
					// fixes issue when changing parts on cards with radio buttons
					// more children kept getting added to entity
					if (node.entity.has(Children))
					{
						node.entity.get(Children).children = new Vector.<Entity>();
					}
					// convert new displayObject for Timeline, if ignoreTimelines flag has not been set to true.
					var removeTimeline:Boolean = true;
					if( !skinPart.isEmpty && metaPart.nextData != null)
					{
						if ( !metaPart.nextData.ignoreTimelines )	// if timelines are ignore we do not cache as bitmap since movieclip is likely manipulated via code
						{
							var hasTimeline:Boolean;
							if ( metaPart.nextData.convertAllTimelines )	// if timelines are ignore we do not cache as bitmap since movieclip is likely manipulated via code
							{
								hasTimeline = ( TimelineUtils.convertAllClips( display.displayObject, node.entity, null, true ) != null );
							}
							else
							{
								hasTimeline = ( TimelineUtils.convertFirstTimeline( display.displayObject, node.entity ) != null );
							}
							removeTimeline = !hasTimeline;
							
							if( PlatformUtils.isMobileOS && !metaPart.nextData.ignoreBitmap && !node.skin.ignoreBitmap )
							{
								var parentEntity:Entity = node.entity.get(Parent).parent;
								var spatial:Spatial = parentEntity.get(Spatial);
								
								if( spatial.scale < 1 )
								{
									var hasInstances:Boolean = DisplayUtils.hasInstances(DisplayObjectContainer(display.displayObject));
											
									// determine scale at which parts should be bitmapped
									// scaleTarget is used to set quality
									/*
									var scaleTarget:Number = spatial.scale * _shellApi.viewportScale;
									if(_shellApi.camera && !ignoreCameraScale)
									{
										scaleTarget *= _shellApi.camera.scale;
									}
									*/
			
									// inflate bound slightly to account for aliasing
									var bounds:Rectangle = display.displayObject.getBounds(display.displayObject);
									bounds.inflate(1, 1);
	
									// if standard part with timelines or symbols, convert into single bitmap
									if( !hasTimeline && !hasInstances )
									{
										// rlh: don't use scaleTarget (0.36) for quality. Use 1.0 instead for best results on mobile
										var wrapper:BitmapWrapper = DisplayUtils.convertToBitmapSprite(display.displayObject, bounds, 1.0, true);
										if(wrapper)
										{
											if( display.bitmapWrapper )
											{
												display.bitmapWrapper.destroy();
											}
											display.bitmapWrapper = wrapper;
											display.displayObject = wrapper.sprite;
										}
									}
									else	// if non-standard part conatining timelines or symbols, convert all clips
									{
										// TODO :: should be able to have Display keep track of all converted BitmapData
										// rlh: don't use scaleTarget (0.36) for quality. Use 1.0 instead for best results on mobile
										display.convertToBitmaps(1.0);
									}
								}
							}
						}
					}
					
					// TODO :: Need to make sure old timeline entities from recursion get removed
					if( removeTimeline )
					{
						node.entity.remove( Timeline );
						node.entity.remove( TimelineClip );
						node.entity.remove( TimelineMaster );
					}
					
					metaPart.replace = true;
					display.invalidate = false;
				}
			}

			// once display is refreshed, refresh Metadata
			if( metaPart.replace )
			{
				if( !skinPart.isEmpty )
				{
					updateMetaData( node );
				}
				else
				{
					if( metaPart.currentData )
					{
						updateMetaData( node, true, false )
						metaPart.currentData.reset();
					}
				}
				metaPart.replace = false;
				loadComplete( node );
			}
		}

		/////////////////////////////////////////////////////////////////////////
		/////////////////////////////  UPDATE VALUE  ////////////////////////////
		/////////////////////////////////////////////////////////////////////////
		
		/**
		 * If SkinPart value has changed, load corresponding metadata 
		 * @param	node
		 * @return
		 */
		private function updateSkinValue( node:SkinNode ):void
		{
			var skinPart:SkinPart = node.skinPart;
			var metaPart:MetaPart = node.metaPart;
			
			// check for values being equal
			if( metaPart.currentData )
			{
				// If nextdata is not null, then current metadata has loaded 
				// and currently in the process of loading/updating next asset
				// If next skinPart.value is same as pending values then ignore.
				if( metaPart.nextData )	
				{
					// if values are equal, already being process so ignore value update
					if( metaPart.nextData.id == skinPart.value )	
					{
						return;
					}
					else if ( DataUtils.validString(metaPart.currentData.pendingId) )													
					{
						if ( metaPart.currentData.pendingId == skinPart.value )	
						{
							return;
						}
					}
				}
				else
				{
					// If nextdata is null & currentData.pendingId is specified 
					// then part xml is still in process of loading.
					// If  next value is same as pending ignore,
					// otherwise allow next value to proceed as it is the more recent value.
					if ( DataUtils.validString(metaPart.currentData.pendingId) )	
					{
						if ( metaPart.currentData.pendingId == skinPart.value )	
						{
							// NOTE :: Don't think we need to reset timeline since this will happen when asset loads.
							//resetPart( node ); // reset part's timelineClips
							//loadComplete( node );
							return;
						}
					}
					// If not waiting on xml load, and current & next value are equal
					// then reset timeline, this ends the value update.
					else if ( metaPart.currentData.id == skinPart.value )	
					{
						resetTimeline( node ); // reset part's timelineClips, and dispatch load complete
						loadComplete( node );
						return;
					}
				}
			}

			// check for value being 'empty'
			if( skinPart.isEmpty )
			{
				skinPart.refreshDisplay = true;
				return;
			}
			
			if( metaPart.hasPart )	// associated with part load metaData
			{
				// use new value to update metadata
				if( metaPart.currentData )	
				{ 
					metaPart.currentData.pendingId = skinPart.value; 
				}
				skinPart.reload = true;
				/**
				 * NOTE :: We set refreshDisplay to false so that we have to wait for data to load first.
				 * Possible that refreshDisplay can get set to true when part gets unhidden,
				 * which can cause part to attempt a display refresh prior to metadata being loaded.
				 * This causes the metadata to update, but for the dispaly to remain the same
				 */
				skinPart.refreshDisplay = false;
				
				// don't pass eye states to eye part
				if ((metaPart.type == SkinUtils.EYES) && ((skinPart.value == EyeSystem.OPEN) || (skinPart.value == EyeSystem.SQUINT)))
				{
					return;
				}
				
				var dataPath:String = _shellApi.dataPrefix + metaPart.dataPath + metaPart.type + "/" + skinPart.value + ".xml";
				
				if(AppConfig.loadMissingPartsFromServer && PlatformUtils.isMobileOS)
				{
					_shellApi.loadFile( dataPath, onDataLoaded, node, dataPath );
				}
				else
				{
					_shellApi.loadFile( dataPath, onDataLoaded, node, dataPath );
				}
			}
			else					// if not part associated, metadata has already been parsed (for skinColor, hairColor, eyeState)
			{
				var colorSet:ColorSet = node.colorSet;
				var state:State = node.entity.get( State );
				
				// apply metadata (this only happens once since the metadata for non-asset skinParts don't change, only their values change)
				if( !metaPart.currentData )	
				{
					metaPart.currentData = metaPart.nextData;
					metaPart.nextData = null;
					if( colorSet )	{ applyMetaDataToColor( node, colorSet ); }
					if( state )		{ applyMetaDataToState( node, state ); }
				}
				
				// apply changes in color value
				if( colorSet )						
				{
					colorSet.setColorAspect( skinPart.value, skinPart.id );
				}
				
				// apply changes in state value
				if( state )							
				{
					state.setState( skinPart.id, skinPart.value );	// this needs to propagate to child states
				}
				
				saveLook( node );	// TODO :: this is getting called too often, investigate. - bard
			}
		}
		
		/**
		 * Reset's timelien if one is available. 
		 * @param node
		 * 
		 */
		private function resetTimeline( node:SkinNode ):void
		{
			// reset part's timelineClips
			if( node.metaPart.hasPart )
			{
				TimelineUtils.resetAll( node.entity );
			}
		}
		
		//////////////////////////////////////////////////////////////////////////
		////////////////////////////////  LOAD XML ///////////////////////////////
		//////////////////////////////////////////////////////////////////////////
		
		/**
		 * Handler for PartMetaData load complete, sets metadata
		 * @param	content
		 * @param	partEntity
		 * @param	skinData
		 */
		public function onDataLoaded( dataXml:XML, node:SkinNode, dataPath:String):void
		{
			var metaPart:MetaPart = node.metaPart;
			var skinPart:SkinPart = node.skinPart;
			if(skinPart){
				var value:String = skinPart.value;
				
				try 
				{
					if ( dataXml != null )
					{
						var partMetaData:PartMetaData = _metaDataParser.parseMetaData( dataXml, value);
						
						// NOTE: on the backend, when a campaign expires, we remove the player’s prize cards from their inventory
						// that list of cards is pulled into the game. If they are a member, we let them keep the cards.
						
						// if not mobile and not member player (has profile) and part has campaign ID and pulling ads from CMS
						if ((!AppConfig.mobile) && (!_shellApi.profileManager.active.isMember) && (!isNaN(partMetaData.campaignID)) && (EntityUtils.getParent(node.entity).get(Profile) != null) && (AppConfig.adsFromCMS))
						{
							trace("Check expiring part for campaign ID: " + partMetaData.campaignID);
							// if campaign ID is not found in list of current campaigns, then replace with default
							var campaignItems:Vector.<String> = _shellApi.getCardSet(CardGroup.CUSTOM, true).cardIds;
							trace("Campaign Items: " + campaignItems);
							if (campaignItems.indexOf(String(partMetaData.campaignID)) == -1)
							{
								trace("Expiring part: remove expired item: " + value);
								skinPart.setValue( SkinUtils.getDefaultPart( skinPart.id ), true );
								return;
							}
							else
							{
								trace("Expiring part: item still active: " + value);
							}
						}
						
						// check that incoming data matches pending id, making sure that data xml didn't load out of order
						if( metaPart.currentData )	
						{ 
							if( DataUtils.validString(metaPart.currentData.pendingId) )
							{
								if( partMetaData.id != metaPart.currentData.pendingId )
								{
									// TODO :: Might need to do some handling here, essentially an xml loaded out of order
									trace( "WARNING :: SkinSystem :: onDataLoaded : xml loaded out of order, part id: " + partMetaData.id + " not the same as pendingId: " + metaPart.currentData.pendingId  );
									return;
								}
							}
						}
						
						metaPart.nextData = partMetaData;	// TODO :: may need to save previous to disable
						skinPart.refreshDisplay = true;
					}
					else
					{
						skinPart.setValue( SkinUtils.getDefaultPart( skinPart.id ), true );
						var message:String = (" SkinSystem :: Part XML not found at : " + dataPath );
						throw new Error( message ); 
					}
					
				}
				catch ( e:Error )
				{
					( "SkinSystem : onDataLoaded : xml for part not found, error: " + e );
					skinPart.reload = false;	// turn off reload 
					
					// Part xml was not found, either allow current part to remain or attempt a reversion or replacement by a default part.
					// attempt revert, returning to permanent value or setting to empty if none exists
					if( skinPart.revertValue() )	// if able to revert, simply ignore attempt and dispatch
					{
						// make sure 'required' parts are not being left empty, if they are we will need to replace them with default values and relaod
						if( skinPart.value == SkinPart.EMPTY && SkinUtils.PARTS_REQUIRED.indexOf( skinPart.id ) != -1 )
						{
							trace( "SkinSystem :: onDataLoaded : attempting to revert to 'empty' for a require part, reload with a default part." );
							skinPart.setValue( SkinUtils.getDefaultPart( skinPart.id ), true );
							return;
						}
						
						trace( "SkinSystem :: onDataLoaded : leave skinPart with current value." );
						skinPart._invalidate = false;	// manually reset invalidate to false, as we don;t want to induce another skin value update by SkinSystem
						skinPart.loaded.dispatch( skinPart );	// dispatch directly so that character loaded process continues, do not want to save results since load failed
					}
					else	// if not able to revert means attempted value is same as permanent, needs to be replaced with previously valid value or default value
					{
						trace( "SkinSystem :: onDataLoaded : set skinPart value back to current value, does not require a reload." );
						defaultWhenFilesNotFount(node);
					}
				}
			}
			
		}
		
		/**
		 * Loading process is complete, checks if look needs to be saved.
		 * Dispatch load complete, used by intial loading systems to determine when character has been fully loaded
		 * as well as handlers.
		 */
		private function loadComplete( node:SkinNode ):void
		{
			// if skin change was permanent save change to profile, saveLook will check for Profile component
			// we wait until loadComplete to save to make sure value was valid
			saveLook( node );
			node.skinPart.loaded.dispatch( node.skinPart );
			
			// rlh: add any associated parts
			if ((node.metaPart.hasPart) && (node.metaPart.currentData != null) && (node.metaPart.currentData.attachments != null))
			{
				// iterate through the attachments
				var attachments:Dictionary = node.metaPart.currentData.attachments;
				for (var id:String in attachments)
				{
					// apply part to parent entity
					var lookAspect:LookAspectData = new LookAspectData( id, attachments[id]); 
					var lookData:LookData = new LookData();
					lookData.applyAspect( lookAspect );
					var parent:Entity = EntityUtils.getParent( node.entity );
					SkinUtils.applyLook( parent, lookData, false );	
				}
			}
		}
				
		/**
		 * Loading process is complete, checks if look needs to be saved.
		 * Dispatch load complete, used by intial loading systems to determine when character has been fully loaded
		 * as well as handlers.
		 */
		private function saveLook( node:SkinNode, toServer:Boolean = false ):void
		{
			// if skin change was permanent save change to profile, saveLook will check for Profile component
			if( node.skinPart.saveValue  )
			{
				var parent:Entity = EntityUtils.getParent( node.entity )
				if ( parent )
				{
					SkinUtils.saveLook( parent );
					if(toServer && parent == _shellApi.player)
					{
						_shellApi.saveLook();
					}
				}
				
				node.skinPart.saveComplete();
			}
		}
		
		/////////////////////////////////////////////////////////////////////////
		///////////////////////////////  LOAD ASSET  ////////////////////////////
		/////////////////////////////////////////////////////////////////////////
		
		private function loadAsset( node:SkinNode ):void
		{
			var metaPart:MetaPart = node.metaPart;
			if (metaPart.nextData != null)
			{
				var assetUrl:String = _shellApi.assetPrefix + metaPart.assetPath + metaPart.nextData.partId + "/" + metaPart.nextData.asset + ".swf"

				if(AppConfig.loadMissingPartsFromServer && PlatformUtils.isMobileOS)
				{
					_shellApi.loadFile( assetUrl, onAssetLoaded, node, assetUrl );
				}
				else
				{
					_shellApi.loadFile( assetUrl, onAssetLoaded, node, assetUrl );
				}
			}
		}
		
		/**
		 * Handler for asset load complete, applies asset to display.
		 * @param	content
		 * @param	partEntity
		 */
		private function onAssetLoaded( asset:MovieClip, node:SkinNode, assetUrl:String ):void
		{
			var skinPart:SkinPart;
			try
			{
				if ( asset != null )
				{
					// swap display
					
					var display:Display = node.display;
					
					// NOTE :: this avoids delay in positioning, assign before swap
					asset.x = display.displayObject.x;
					asset.y = display.displayObject.y;
					
					display.swapDisplayObject( asset );

					display.displayObject.mouseEnabled = false;
					display.displayObject.mouseChildren = false;
				}
				else
				{
					defaultWhenFilesNotFount(node);
					var message:String = (" PartSystem :: Part asset not found at : " + assetUrl );
					throw new Error( message ); 
				}
			}
			catch ( e:Error )
			{
				trace( e );
				
				// dispatch directly, do not want to save results since load failed
				skinPart = node.skinPart;
				if( skinPart )
				{
					defaultWhenFilesNotFount(node);
					// USED FOR TESTING
					if( errorSignal )
					{
						if( errorSignal.numListeners > 0 )
						{
							errorSignal.dispatch( "Missing " + skinPart.value + ".swf of type: " + skinPart.id + " with url: " + assetUrl );
						}
					} 
				}
				else
				{
					if( errorSignal )
					{
						if( errorSignal.numListeners > 0 )
						{
							errorSignal.dispatch( "Missing SkinPart component, Entity has likely already been removed by time handler is called." );
						}
					} 
				}
			}
		}
		
		private function defaultWhenFilesNotFount(node:SkinNode):void
		{
			var metaPart:MetaPart = node.metaPart;
			var skinPart:SkinPart = node.skinPart;
			
			if( metaPart.currentData != null )	// if metaPart.currentData is true, then a previous has been successfully loaded, revert value to 
			{
				skinPart.setValue( metaPart.currentData.id, true );
				skinPart._invalidate = false;	// manually reset invalidate to false, as we don;t want to induce another skin value update by SkinSystem
				saveLook(node, true);
				skinPart.loaded.dispatch( skinPart );	// dispatch directly so that character loaded process continues, do not want to save results since load failed
			}
			else
			{
				trace( "SkinSystem :: onDataLoaded : there is no current value, reload with a default part." );
				skinPart.setValue( SkinUtils.getDefaultPart( skinPart.id ), true );	// NOTE :: for now setting replacement as permanent, may want to reconsider. -bard
				skinPart.loaded.addOnce(Command.create(lookReadyToSave, node));
			}
		}
		
		private function lookReadyToSave(part:SkinPart, node:SkinNode):void {
			saveLook(node, true);
		}
		/////////////////////////////////////////////////////////////////////////
		/////////////////////////////  UPDATE METADATA  //////////////////////////
		/////////////////////////////////////////////////////////////////////////
		
		private function updateMetaData( node:SkinNode, remove:Boolean = true, apply:Boolean = true ):void
		{
			var currentData:PartMetaData = node.metaPart.currentData;
			var colorSet:ColorSet = node.entity.get( ColorSet );
			var skinPart:SkinPart;
			var charEntity:Entity;
			var i:int;
			var j:int;
			
			// remove current metadata before apply new metadata
			if( remove )
			{
				if ( currentData )
				{
					// un-hide parts that current metadata hides
					if ( currentData.hiddenParts )
					{
						for ( i = 0; i < currentData.hiddenParts.length; i++ )
						{
							skinPartEntity = node.skin.getSkinPartEntity( currentData.hiddenParts[i] );
							if( skinPartEntity == null )	{ continue; }
							skinPart = skinPartEntity.get( SkinPart );
							skinPart.hidden = false;
							skinPart.refreshDisplay = true;
							
							// NOTE :: If a part is hidden, the parts it is hiding should become unhidden.
							// When the part that was hiding it is removed, the previously hidden part should reapply its hiding.
							hiddenMetaPart = skinPartEntity.get( MetaPart );
							if( hiddenMetaPart )
							{
								if( hiddenMetaPart.currentData )
								{
									if( hiddenMetaPart.currentData.hiddenParts )
									{
										for ( j=0; j < hiddenMetaPart.currentData.hiddenParts.length; j++ )
										{		
											skinPartEntity = node.skin.getSkinPartEntity( hiddenMetaPart.currentData.hiddenParts[j] );
											if( skinPartEntity == null )	{ continue; }
											skinPart = skinPartEntity.get( SkinPart );
											skinPart.hidden = true;	// hidden determines Display visibility within PartSystem
											skinPart.refreshDisplay = true;
										}
									}
								}
							}
						}
					}
					
					// remove components prevously added
					if ( currentData.components )
					{
						for ( i = currentData.components.length - 1; i >= 0; --i )
						{
							var currentComponent:Component = currentData.components[i];
							var componentClass:Class = ClassUtils.getClassByObject(currentComponent);
							node.entity.remove( componentClass );
						}
					}
					
					// Remove special ability
					if( currentData.special )
					{
						charEntity = node.entity.get(Parent).parent;
						CharUtils.removeSpecialAbility(charEntity, currentData.special);
						currentData.special = null;
					}
					
					// remove color
					if( colorSet )
					{
						removeMetaDataToColor( node, colorSet );
					}
				}
			}
			
			if( apply )
			{
				node.metaPart.currentData = node.metaPart.nextData;	// assign next metaData to current
				node.metaPart.nextData = null;
				currentData = node.metaPart.currentData;
				if(currentData == null)
					return;
				
				if ( currentData.id != SkinPart.EMPTY )
				{
					// hide parts specified by metadata
					if ( currentData.hiddenParts )
					{
						var skinPartEntity:Entity;
						var hiddenskinPartEntity:Entity;
						var hiddenMetaPart:MetaPart;
						
						for ( i=0; i < currentData.hiddenParts.length; i++ )
						{
							skinPartEntity = node.skin.getSkinPartEntity( currentData.hiddenParts[i] );
							if( skinPartEntity == null )
							{
								continue;
							}
							skinPart = skinPartEntity.get( SkinPart );
							node.skin.partLoaded(skinPart);
							skinPart.hidden = true;	// hidden determines Display visibility within PartSystem
							
							// RLH: don't refresh but just hide part instead
							//skinPart.refreshDisplay = true;
							skinPart.refreshDisplay = false;
							var disp:Display = skinPartEntity.get(Display);
							if (disp)
							{
								disp.visible = false;
							}
							
							// TODO :: if hidden need to also hide/revert any colors associated
							
							// NOTE :: If a part is hidden, the parts it is hiding should become unhidden
							// when the part that was hiding it is removed, the previously hidden part should reapply its hiding.
							hiddenMetaPart = skinPartEntity.get( MetaPart );
							if( hiddenMetaPart )
							{
								if( hiddenMetaPart.currentData )
								{
									if( hiddenMetaPart.currentData.hiddenParts )
									{
										for ( j=0; j < hiddenMetaPart.currentData.hiddenParts.length; j++ )
										{
											if( currentData.hiddenParts.indexOf(hiddenMetaPart.currentData.hiddenParts[j]) == -1 )
											{
												skinPartEntity = node.skin.getSkinPartEntity( hiddenMetaPart.currentData.hiddenParts[j] );
												if( skinPartEntity == null )	{ continue; }
												skinPart = skinPartEntity.get( SkinPart );
												skinPart.hidden = false;	// hidden determines Display visibility within PartSystem
												skinPart.refreshDisplay = true;
											}
										}
									}
								}
							}
						}
					}
					
					// TODO :: In some cases may needs to be added to character Entity instead of part Entity?
					if ( currentData.components )
					{
						var newComponent:Component;
						for ( i=0; i < currentData.components.length; i++ )
						{
							newComponent = currentData.components[i];
							// RLH: this sometimes is null
							if (newComponent)
								node.entity.add(newComponent);
						}
					}
					
					// Add the special ability if it's the player
					if( node.skin.allowSpecialAbilities )
					{
						if( currentData.special )
						{
							if( !charEntity )
							{
								charEntity = node.entity.get(Parent).parent;
							}
							// added an additional check later that can allow npcs to have special abilites without breaking
							//if(player.get(Player)) 
							//{
								if( currentData.special.isValidIsland( super.group.shellApi.island ) )
								{
									CharUtils.addSpecialAbility( charEntity, currentData.special, true);
								}
							//}
						}
					}
					
					// apply color
					if( colorSet )
					{
						applyMetaDataToColor( node, colorSet );
					}
					
					// apply state
					var state:State = node.entity.get( State );
					if( state )
					{
						applyMetaDataToState( node, state );
					}
					
					// TODO :: update direction
					// TODO :: update layering
				}
			}
		}
		
		private function removeMetaDataToColor( node:SkinNode, colorSet:ColorSet ):void
		{
			// remove colorAspects added by previous metadata, invalidate ColorSets effected
			var previousSkinPartId:SkinPartId = new SkinPartId( node.metaPart.currentData.partId, node.metaPart.currentData.id );
			var colorAspect:ColorAspectData;
			
			// check color aspects in reverse, removing any that are related with exiting part
			if( colorSet.colorAspects.length > 0 )
			{
				var i:int = colorSet.colorAspects.length - 1;
				for ( i; i >= 0; i-- )
				{
					colorAspect = colorSet.colorAspects[i];
					if ( colorAspect.skinPartId.equals(previousSkinPartId) )
					{
						colorAspect.remove();	// remove method handles interdependencies of child parent relationships
					}
				}
			}
		}
		
		/**
		 * Apply metadata information to ColorSet
		 * @param	node
		 */
		private function applyMetaDataToColor( node:SkinNode, colorSet:ColorSet ):void
		{
			colorSet.invalidate = true;
			
			var metaData:PartMetaData = node.metaPart.currentData;
			var skinPartId:SkinPartId = new SkinPartId( metaData.partId, metaData.id );
			
			var partEntity:Entity;
			var colorable:ColorableData;
			var colorAspect:ColorAspectData;
			var childColorAspect:ColorAspectData;
			var parentColorAspect:ColorAspectData;
			var i:int;
			var j:int;

			// update colorableClips
			colorSet.colorableClips.length = 0;
			if ( metaData.colorables )
			{
				for ( i=0; i < metaData.colorables.length; i++ )
				{
					colorable = metaData.colorables[i];
					colorSet.colorableClips.push( colorable );
				} 
			}

			// update colorAspects
			if ( metaData.colorAspects )
			{
				// apply new colorAspects
				var metaColorAspect:ColorAspectData;
				for ( i=0; i < metaData.colorAspects.length; i++ )
				{
					metaColorAspect = metaData.colorAspects[i];
					colorSet.addColorAspect( skinPartId.clone(), metaColorAspect.id, metaColorAspect.value );
				}
			}
			
			// update color Retrieving
			if ( metaData.retrieveColors )
			{
				var retrieving:ColorByPartData;
				var parentColorSet:ColorSet;

				for ( i=0; i < metaData.retrieveColors.length; i++ )
				{
					retrieving = metaData.retrieveColors[i];
					
					// get retrieved color
					partEntity = node.skin.getSkinPartEntity( retrieving.partId );
					if( partEntity == null )	{ continue; }
					parentColorSet = partEntity.get( ColorSet ) as ColorSet;
					if ( DataUtils.validString( retrieving.partColorId) )
					{
						parentColorAspect = parentColorSet.getColorAspect( retrieving.partColorId )
					}
					else
					{
						parentColorAspect = parentColorSet.getColorAspectLast();
						// TODO :: don't just want the last one, want the most recent, if this changes so should children
					}

					if ( parentColorAspect )
					{
						// get colorApect retrieved color will apply to
						if ( DataUtils.validString( retrieving.colorId ) )
						{
							colorAspect = colorSet.getColorAspect( retrieving.colorId );
						}
		
						if ( colorAspect == null )	// If no colorAspect exist, create a new one
						{
							// TODO :: Not sure about this SkinPartId
							colorAspect = colorSet.addColorAspect( new SkinPartId( retrieving.partId ), parentColorAspect.id );
						}
		
						colorAspect.parentColor = parentColorAspect;	// adds colorAspect as child of parent
						colorAspect.invalidate = true;
					}
				}
			}
			
			// update color Applying
			if ( metaData.applyColors )
			{
				var applying:ColorByPartData;
				var childColorSet:ColorSet;

				for ( i=0; i < metaData.applyColors.length; i++ )
				{
					// get colorAspect to be applied, from this entity's ColorSet
					applying = metaData.applyColors[i];
					if ( DataUtils.validString( applying.colorId ) )
					{
						colorAspect = colorSet.getColorAspect( applying.colorId );
					}
					else
					{
						colorAspect = colorSet.getColorAspectLast();
					}
					
					if ( colorAspect == null )	// If no colorAspect exist, create a new one
					{
						colorAspect = colorSet.addColorAspect( skinPartId.clone(), applying.colorId );
					}
				
					// get colorAspect being applied to, from other entities' ColorSets
					partEntity = node.skin.getSkinPartEntity( applying.partId );
					if( partEntity == null )	{ continue; }
					childColorSet = partEntity.get( ColorSet ) as ColorSet;
					if ( DataUtils.validString( applying.partColorId ) )
					{
						childColorAspect = childColorSet.getColorAspect( applying.partColorId );
						if ( childColorAspect == null )	// If no colorAspect exist, create a new one
						{
							childColorAspect = childColorSet.addColorAspect( skinPartId.clone(), applying.partColorId );
							// want this color aspect to inherent children
						}
					}
					else
					{
						childColorAspect = childColorSet.getColorAspectLast();	// applies color to last color
						if( !childColorAspect ) 	// If no colorAspect exist, create a new one with no colorId 
						{
							childColorAspect = childColorSet.addColorAspect( skinPartId.clone() );
						}
					}
					
					// add applied to colorAspect to applying colorAspects list of children
					//childColorAspect.value = colorAspect.value;
					colorAspect.addChildColor( childColorAspect );
					childColorAspect.invalidate = true;
				}
			}
		}
		
		/**
		 * Use Metadata's applyStates list to make necessary connections for use with States
		 * @param	node
		 */
		private function applyMetaDataToState( node:SkinNode, state:State ):void
		{
			var metaData:PartMetaData = node.metaPart.currentData;

			// if StateData defined, create State component
			if( metaData.state )
			{
				var applyData:StateData = state.addStateData( metaData.state );	// if StateData already exists it is returned 
				
				// update other States that metaData specifies to apply to
				if ( metaData.applyStates )
				{
					var applyingPartData:StateByPartData;
					var childStateComponent:State;
					var childStateData:StateData;
					var partEntity:Entity
					
					for ( var i:int =0; i < metaData.applyStates.length; i++ )
					{
						// get StateByPartData to be applied
						applyingPartData = metaData.applyStates[i];
						
						// get State being applied to, if none exists create a new State component and add it to skin part Entity
						partEntity = node.skin.getSkinPartEntity( applyingPartData.partId );
						if( partEntity == null )	{ continue; }
						childStateComponent = partEntity.get( State );
						if( !childStateComponent )
						{
							childStateComponent = new State();
							partEntity.add( childStateComponent );
						}
						
						// get StateData being applied to, if none exists create a new StateData and add it to State component
						childStateData = childStateComponent.getState( applyingPartData.partStateId );
						if ( childStateData == null )	// If no StateData exist, create a new one
						{
							childStateData = childStateComponent.addState( applyingPartData.partStateId );
						}
						
						// make child-parent reference, apply value
						applyData.addChildState( childStateData );
						childStateData.value = applyData.value;
						childStateComponent.invalidate = true;
					}
				} 
			}
		}

		[Inject]
		public var _shellApi:ShellApi;
		protected var _nodes:NodeList;
		protected var _metaDataParser:PartMetaDataParser
		//protected var _dataPath:String = "entity/character/parts/";
		//protected var _assetPath:String = "entity/character/";
		public var errorSignal:Signal;
		public var ignoreCameraScale:Boolean = false;
	}
}
