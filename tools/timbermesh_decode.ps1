<#
.SYNOPSIS
    Decompresses, recursively decodes, and saves the full plain-text structure 
    of a Timberborn .timbermesh file.
.PARAMETER Path
    The literal path to the source .timbermesh asset.
.PARAMETER OutputPath
    Optional explicit path for the output text file. Defaults to [AssetName].decoded.txt
#>
param (
    [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
    [string]$Path,
    
    [Parameter(Mandatory=$false)]
    [string]$OutputPath
)

# 1. Path Processing & Environment Validation
$literalPath = Resolve-Path $Path -ErrorAction SilentlyContinue
if (-not $literalPath) {
    Write-Error "Error: Source asset file not found at path: $Path"
    return
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $savePath = Join-Path (Split-Path $literalPath.Path) "$([System.IO.Path]::GetFileNameWithoutExtension($literalPath.Path)).decoded.txt"
} else {
    $savePath = $OutputPath
}

Write-Host "Reading binary asset stream..." -ForegroundColor Cyan
$bytes = [System.IO.File]::ReadAllBytes($literalPath.Path)

if ($bytes.Length -lt 2) {
    Write-Error "Error: Binary file payload is missing or corrupted."
    return
}

# 2. Extract Zlib Layer Framework
if ($bytes[0] -eq 0x78) {
    $skipBytes = 2
    Write-Host "Zlib signature detected (0x789C). Allocating inflation stream..." -ForegroundColor Green
} else {
    $skipBytes = 0
    Write-Warning "Missing standard zlib initialization vector. Proceeding with raw data frame..."
}

try {
    $msInput = [System.IO.MemoryStream]::new($bytes, $skipBytes, $bytes.Length - $skipBytes)
    $deflate = [System.IO.Compression.DeflateStream]::new($msInput, [System.IO.Compression.CompressionMode]::Decompress)
    $msOutput = [System.IO.MemoryStream]::new()
    $deflate.CopyTo($msOutput)
    $protoBytes = $msOutput.ToArray()
    Write-Host "Inflation processing complete. Uncompressed payload size: $($protoBytes.Length) bytes." -ForegroundColor Green
} catch {
    Write-Error "Critical Stream Exception: Failed to inflate compressed block layer. $_"
    return
}

# 3. Text Accumulation Engine Initialization
$textLog = [System.Collections.Generic.List[string]]::new()
$textLog.Add("================================================================================")
$textLog.Add("TIMBERMESH STRUCTURAL DECODE")
$textLog.Add("Source Asset: $($literalPath.Path)")
$textLog.Add("Export Timestamp: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')")
$textLog.Add("Uncompressed Wire Size: $($protoBytes.Length) bytes")
$textLog.Add("================================================================================")

# 4. Low-Level Protobuf Decoding Subsystems
function Read-Varint($stream) {
    $value = [uint64]0
    $shift = 0
    while ($true) {
        $b = $stream.ReadByte()
        if ($b -lt 0) { return $null }
        
        $part = [uint64]($b -band 0x7F)
        $value = $value -bor ($part -shl $shift)
        
        if (($b -band 0x80) -eq 0) { break }
        $shift += 7
        if ($shift -ge 64) { throw "Varint bit parsing overflow encountered." }
    }
    return $value
}

function Parse-ProtobufStructure($payloadBytes, $messageType, $indent = "") {
    $stream = [System.IO.MemoryStream]::new($payloadBytes)
    
    # State tracking variables for decoding packed scalar tables sequentially
    $vpScalarType = 0
    $vpDimension = 1
    
    while ($stream.Position -lt $stream.Length) {
        $tag = Read-Varint $stream
        if ($null -eq $tag) { break }
        
        $wireType = $tag -band 0x7
        $fieldNumber = $tag -shr 3
        
        # Safely read wire segment blocks to maintain precise stream alignment alignment
        $varintVal = $null
        $fixed64Buf = $null
        $lengthDelimitedBuf = $null
        $fixed32Buf = $null
        
        switch ($wireType) {
            0 {
                $varintVal = Read-Varint $stream
            }
            1 {
                $buf = New-Object byte[] 8
                [void]$stream.Read($buf, 0, 8)
                $fixed64Buf = $buf
            }
            2 {
                $len = Read-Varint $stream
                $buf = New-Object byte[] $len
                if ($len -gt 0) {
                    [void]$stream.Read($buf, 0, $len)
                }
                $lengthDelimitedBuf = $buf
            }
            5 {
                $buf = New-Object byte[] 4
                [void]$stream.Read($buf, 0, 4)
                $fixed32Buf = $buf
            }
            default {
                $textLog.Add("${indent}!! Warning: Encountered unexpected wire allocation index ($wireType) at position $($stream.Position). Execution halted.")
                return
            }
        }
        
        # Schema-Driven Field Mapping Sequence
        switch ($messageType) {
            "Model" {
                switch ($fieldNumber) {
                    1 { $textLog.Add("${indent}Model Version = $varintVal") }
                    2 { $textLog.Add("${indent}Model Name = `"$([System.Text.Encoding]::ASCII.GetString($lengthDelimitedBuf))`"") }
                    3 {
                        $textLog.Add("${indent}Node Reference [repeated Node]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "Node" ($indent + "  ")
                    }
                    default { $textLog.Add("${indent}Field $fieldNumber [Unknown Model Field, WireType=$wireType]") }
                }
            }
            "Node" {
                switch ($fieldNumber) {
                    1 {
                        $signedParent = $varintVal
                        if ($varintVal -eq 18446744073709551615) { $signedParent = -1 }
                        elseif ($varintVal -and 0x80000000) {
                            $signedParent = [System.BitConverter]::ToInt32([System.BitConverter]::GetBytes([uint64]$varintVal), 0)
                        }
                        $textLog.Add("${indent}Parent Node ID = $signedParent")
                    }
                    2 { $textLog.Add("${indent}Node Name = `"$([System.Text.Encoding]::ASCII.GetString($lengthDelimitedBuf))`"") }
                    3 {
                        $textLog.Add("${indent}Transform Position [Vector3Float]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "Vector3Float" ($indent + "  ")
                    }
                    4 {
                        $textLog.Add("${indent}Transform Rotation [QuaternionFloat]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "QuaternionFloat" ($indent + "  ")
                    }
                    5 {
                        $textLog.Add("${indent}Transform Scale [Vector3Float]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "Vector3Float" ($indent + "  ")
                    }
                    6 { $textLog.Add("${indent}Total Vertex Count = $varintVal") }
                    7 {
                        $textLog.Add("${indent}Vertex Property [repeated VertexProperty]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "VertexProperty" ($indent + "  ")
                    }
                    8 {
                        $textLog.Add("${indent}Mesh Geometry Node [repeated Mesh]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "Mesh" ($indent + "  ")
                    }
                    9 {
                        $textLog.Add("${indent}Vertex Animation Track [repeated VertexAnimation]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "VertexAnimation" ($indent + "  ")
                    }
                    10 {
                        $textLog.Add("${indent}Node Animation Track [repeated NodeAnimation]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "NodeAnimation" ($indent + "  ")
                    }
                    default { $textLog.Add("${indent}Field $fieldNumber [Unknown Node Field, WireType=$wireType]") }
                }
            }
            "Vector3Float" {
                $fVal = [System.BitConverter]::ToSingle($fixed32Buf, 0)
                switch ($fieldNumber) {
                    1 { $textLog.Add("${indent}X = $fVal") }
                    2 { $textLog.Add("${indent}Y = $fVal") }
                    3 { $textLog.Add("${indent}Z = $fVal") }
                }
            }
            "QuaternionFloat" {
                $fVal = [System.BitConverter]::ToSingle($fixed32Buf, 0)
                switch ($fieldNumber) {
                    1 { $textLog.Add("${indent}X = $fVal") }
                    2 { $textLog.Add("${indent}Y = $fVal") }
                    3 { $textLog.Add("${indent}Z = $fVal") }
                    4 { $textLog.Add("${indent}W = $fVal") }
                }
            }
            "Mesh" {
                switch ($fieldNumber) {
                    1 {
                        $idxStream = [System.IO.MemoryStream]::new($lengthDelimitedBuf)
                        $indices = [System.Collections.Generic.List[int]]::new()
                        while ($idxStream.Position -lt $idxStream.Length) {
                            $idxVal = Read-Varint $idxStream
                            if ($null -ne $idxVal) { $indices.Add([int]$idxVal) }
                        }
                        $textLog.Add("${indent}Indices Vector (Count=$($indices.Count)) = [" + ($indices -join ", ") + "]")
                    }
                    2 { $textLog.Add("${indent}Material Name = `"$([System.Text.Encoding]::ASCII.GetString($lengthDelimitedBuf))`"") }
                    default { $textLog.Add("${indent}Field $fieldNumber [Unknown Mesh Field, WireType=$wireType]") }
                }
            }
            "VertexProperty" {
                switch ($fieldNumber) {
                    1 { $textLog.Add("${indent}Attribute ID = `"$([System.Text.Encoding]::ASCII.GetString($lengthDelimitedBuf))`"") }
                    2 {
                        $vpScalarType = [int]$varintVal
                        $typeName = switch ($vpScalarType) {
                            0 { "UNSPECIFIED" }
                            1 { "UNSIGNED_BYTE" }
                            2 { "UNSIGNED_INT" }
                            3 { "INT" }
                            4 { "FLOAT" }
                            5 { "DOUBLE" }
                            default { "UNKNOWN" }
                        }
                        $textLog.Add("${indent}Scalar Encoding Type = $vpScalarType ($typeName)")
                    }
                    3 {
                        $vpDimension = [int]$varintVal
                        $textLog.Add("${indent}Vector Layout Dimension = $vpDimension")
                    }
                    4 {
                        if ($vpScalarType -eq 4) { # SCALAR_TYPE_FLOAT
                            $elemCount = $lengthDelimitedBuf.Length / 4
                            $tuples = [System.Collections.Generic.List[string]]::new()
                            for ($i = 0; $i -lt $elemCount; $i += $vpDimension) {
                                $coords = @()
                                for ($d = 0; $d -lt $vpDimension; $d++) {
                                    if ((($i + $d) * 4) -lt $lengthDelimitedBuf.Length) {
                                        $coords += [System.BitConverter]::ToSingle($lengthDelimitedBuf, (($i + $d) * 4))
                                    }
                                }
                                $tuples.Add("(" + ($coords -join ", ") + ")")
                            }
                            $textLog.Add("${indent}Decoded Scalar Data Matrix (Total Floats=$elemCount):")
                            for ($m = 0; $m -lt $tuples.Count; $m += 4) {
                                $endIdx = [Math]::Min($m+3, $tuples.Count-1)
                                $chunk = $tuples[$m..$endIdx] -join "   "
                                $textLog.Add("${indent}  [$m..$endIdx]: $chunk")
                            }
                        } else {
                            $hexSnippet = [System.BitConverter]::ToString($lengthDelimitedBuf)
                            if ($hexSnippet.Length -gt 45) { $hexSnippet = $hexSnippet.Substring(0, 42) + "..." }
                            $textLog.Add("${indent}Decoded Byte Segment (Raw Hex Length=$($lengthDelimitedBuf.Length)) = $hexSnippet")
                        }
                    }
                    default { $textLog.Add("${indent}Field $fieldNumber [Unknown VertexProperty Field, WireType=$wireType]") }
                }
            }
            "VertexAnimation" {
                switch ($fieldNumber) {
                    1 { $textLog.Add("${indent}Animation Frame Key = `"$([System.Text.Encoding]::ASCII.GetString($lengthDelimitedBuf))`"") }
                    2 { $textLog.Add("${indent}Playback Framerate = $([System.BitConverter]::ToSingle($fixed32Buf, 0)) FPS") }
                    3 { $textLog.Add("${indent}Target Animated Vertices = $varintVal") }
                    4 {
                        $textLog.Add("${indent}Deformation Frame [VertexAnimationFrame]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "VertexAnimationFrame" ($indent + "  ")
                    }
                    default { $textLog.Add("${indent}Field $fieldNumber [Unknown VertexAnimation Field, WireType=$wireType]") }
                }
            }
            "VertexAnimationFrame" {
                switch ($fieldNumber) {
                    1 {
                        $textLog.Add("${indent}Frame Property Vector:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "VertexProperty" ($indent + "  ")
                    }
                    default { $textLog.Add("${indent}Field $fieldNumber [Unknown VertexAnimationFrame Field, WireType=$wireType]") }
                }
            }
            "NodeAnimation" {
                switch ($fieldNumber) {
                    1 { $textLog.Add("${indent}Timeline Identifier = `"$([System.Text.Encoding]::ASCII.GetString($lengthDelimitedBuf))`"") }
                    2 { $textLog.Add("${indent}Timeline Framerate = $([System.BitConverter]::ToSingle($fixed32Buf, 0)) FPS") }
                    3 {
                        $textLog.Add("${indent}Keyframe Node [NodeAnimationFrame]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "NodeAnimationFrame" ($indent + "  ")
                    }
                    default { $textLog.Add("${indent}Field $fieldNumber [Unknown NodeAnimation Field, WireType=$wireType]") }
                }
            }
            "NodeAnimationFrame" {
                switch ($fieldNumber) {
                    1 {
                        $textLog.Add("${indent}Frame Delta Position [Vector3Float]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "Vector3Float" ($indent + "  ")
                    }
                    2 {
                        $textLog.Add("${indent}Frame Delta Rotation [QuaternionFloat]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "QuaternionFloat" ($indent + "  ")
                    }
                    3 {
                        $textLog.Add("${indent}Frame Delta Scale [Vector3Float]:")
                        Parse-ProtobufStructure $lengthDelimitedBuf "Vector3Float" ($indent + "  ")
                    }
                    default { $textLog.Add("${indent}Field $fieldNumber [Unknown NodeAnimationFrame Field, WireType=$wireType]") }
                }
            }
        }
    }
}

# 5. Core Engine Execution Loop
Write-Host "De-serializing mesh wireframes and hierarchical nested matrices..." -ForegroundColor Yellow
Parse-ProtobufStructure $protoBytes "Model"

# 6. Disk IO Serialization Sequence
try {
    Write-Host "Writing structural dataset to target output path..." -ForegroundColor Cyan
    [System.IO.File]::WriteAllLines($savePath, $textLog)
    Write-Host "Success! Readable text file successfully compiled at:" -ForegroundColor Green
    Write-Host "$savePath" -ForegroundColor White
} catch {
    Write-Error "Failed to write output text data to file: $_"
}