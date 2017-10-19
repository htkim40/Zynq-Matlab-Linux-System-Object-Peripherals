classdef base < matlab.System & matlab.system.mixin.Propagates &...
        coder.ExternalDependency & matlab.system.mixin.CustomIcon
    %SEND Summary of this class goes here
    %   Detailed explanation goes here
    
    properties (Nontunable)
        % CAN Device
        %
        % The CAN device name
        % On most systems, this will be canN (e.g. can0)
        CANDev = 'can0';
    end
    
    properties (Hidden, Access = protected)
        % CAN Socket
        socket = int32(0);
    end
    
    methods (Access = protected)
        function releaseImpl(obj)
            if coder.target('Rtw')
                coder.ceval('closeCANSocket', obj.socket);
            end
        end
    end
    
    %% Execution Mode
    methods (Hidden, Static, Access = protected)
        function flag = showSimulateUsingImpl
            flag = false;
        end
        function simMode = getSimulateUsingImpl
            simMode = 'Interpreted execution';
        end
    end
    
    %% Helper
    methods (Hidden, Access = protected)
        function openSocket(obj, nfilt, ids, masks)
            obj.socket = coder.nullcopy(int32(0));
            if coder.target('Rtw')
                coder.cinclude('can_include.h');
                
                if nfilt == 0
                    idVals = uint32(0);
                    maskVals = uint32(0);
                else
                    idVals = uint32(ids);
                    maskVals = uint32(masks);
                end
                
                obj.socket = coder.ceval('getCANSocket',...
                    ntstr(obj,obj.CANDev), uint32(nfilt), ...
                    coder.rref(idVals), coder.rref(maskVals));
                if (obj.socket < 0)
                    coder.ceval('exit', uint32(1));
                end 
            end
        end
        function s = ntstr(obj, in) %#ok<INUSL>
            s = coder.const([in char(0)]);
        end
    end
    
        %% External Dependency Methods
    methods (Static)
        
        function tf = isSupportedContext(bldCfg)
            % isSupportedContext Check if context is supported
            %
            % Determine if build context supports external dependency
            if bldCfg.isCodeGenTarget('rtw')
                tf = true;
            else
                error('CAN Send is not supported for this target');
            end
        end
        
        function updateBuildInfo(buildInfo,bldCfg)
            % updateBuildInfo update the build for code generation
            %
            % Add required source, include and linker files to the build
            
            rootDir = RTW.transformPaths(fileparts(strtok(mfilename('fullpath'),'+')));

            if bldCfg.isCodeGenTarget('rtw')
                % include libiio
                buildInfo.addIncludePaths(...
                    fullfile(rootDir, 'include'));
                buildInfo.addSourcePaths(...
                    fullfile(rootDir, 'src'));
                buildInfo.addSourceFiles({...
                    'can_API.c',...
                });
            end
        end
    end
    
end

